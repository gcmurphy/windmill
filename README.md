# osquery-tls-server

A TLS endpoint for delivering osquery configuration files to nodes. The quickest
way to get started is to [![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

If you deploy to Heroku using the button above, you'll need to view the
environment variables to get the random secret that was generated for the NODE_ENROLL_SECRET
used by the windmill application.

## Compatibility

This has been tested most recently against osquery version 1.5.1-59-g43cf5f1

## Running the server

For security purposes, the software requires new endpoints to supply a shared
secret which is found in an environment variable named NODE_ENROLL_SECRET.

To run the server run the following commands. The first two commands should only
need to be run once

```
bundle install
rake db:setup
ruby server.rb
```

If you want to use the faster puma server you can run the app with this command:

```
puma -C puma.rb
```

Since this was written by a Heroku employee intending to run this on Heroku if
you run the app in production the code expects an environment variable named
DATABASE_URL with a url pointing to a postgres database. Absent that variable,
production mode will fall back to a postgres database on localhost.

## Configuring osqueryd

The easiest way to configure osqueryd is to put your command line options
into a flag file. By default on linux systems, osqueryd will look for
`/etc/osquery/osquery.flags` You need to have the following options set there
for osqueryd to look to your server.

```
--tls_hostname=dns.name.of.your.server.with.no.https.on.the.front.com
--config_plugin=tls
--config_tls_endpoint=/api/config
--config_tls_refresh=14400
--enroll_tls_endpoint=/api/enroll
--enroll_secret_path=/etc/osquery/osquery.secret
```

The lines above seem to be the minimum necessary to make osquery pull config
from a TLS endpoint. You will need to populate the `/etc/osqueryd/osqueryd.secret`
file with the value of your NODE_ENROLL_SECRET environment variable. Additional
lines that you may include in your osquery.flags file include:

```
--database_path=/var/osquery/osquery.db
--schedule_splay_percent=10
--logger_plugin=syslog
--logger_syslog_facility=3
--log_results_events=true
--verbose
```

Then you can start osqueryd (on linux) with a simple `/etc/init.d/osqueryd start`
or `service start osqueryd`

## Enrolling osquery endpoints
The osquery endpoints will reach out to the TLS server and send a POST to `/api/enroll`
with a `enroll_secret` value that it read from it's own filesystem (`/etc/osquery/osquery.secret`
if you followed the `osquery.flags` file above). The value in that file must match
the node secret being used by the TLS server and specify a configuration group. The TLS server takes node secret value from an
environment variable named NODE_ENROLL_SECRET. If you have not set that variable
then it defaults to "valid_test".

If the server sends a valid node_secret then it will be enrolled and joined to the configuration
group that was specified. The endpoint will receive a node key that it
can use to pull its configuration from the server.

You can also store a host identifier for osquery endpoints by adding
a host identifier to the front of the group label and enroll secret stored in `/etc/osquery/osquery.secret`.
The values are separated by a colon.

### Example osquery.secret

`www-1:web:bigrandomstringofcharactersforthewin`

That will label the endpoint with an identifier of `www-1` and join it to the `web`
configuration group. From that point on it will receive the configuration file that
the `web` configuration group assigns to that endpoint.

If you enroll an endpoint with an invalid configuration group name or a missing
configuration group name it will be added to the `default` configuration group.

## Serving configuration files
Configuration files are kept in a database and are assigned to endpoints by the
configuration group to which they belong. When the application is initialized a
configuration group named `default` is created automatically and a default configuration
file is added to that group.

Additional configuration groups and configuration files can be added by pointing
your browser at the root of the application. There you will find a GUI for adding
new configuration groups and new configuration files.

After an endpoint is enrolled it will make a POST request to /api/config and provide
the node secret it was given when it enrolled. The Windmill server will look up that
node secret and find the configuration file that is assigned to that endpoint and
provide that back to the endpoint.

## Helpful links

* The reference implementation in python: https://github.com/facebook/osquery/blob/master/tools/tests/test_http_server.py
* The documentation: https://github.com/facebook/osquery/blob/master/docs/wiki/deployment/remote.md

## Running tests

The tests are written in RSpec and make use of the `rack-test` gem. If you do a
`bundle install` you should have that. Since the application uses a database to
keep track of node_keys, you'll need to prepare the database before the first
time you run the tests. `RACK_ENV=test rake db:migrate`. It shouldn't be that way
and there is a bug waiting to be fixed: https://github.com/blackfist/windmill/issues/8

So you can just run `rspec spec` to run
the tests.
