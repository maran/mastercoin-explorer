## Mastercoin-explorer ##
This is a rails project that parses and saves Mastercoin data. You can see it working on [mastercoin-explorer.com](http://mastercoin-explorer.com).

### Prerequisites ###

In order to make use of this application you will need a fully up-to-date [bitcoin-ruby](http://github.com/lian/bitcoin-ruby) node. Please note that a fully synced nodes takes up around 40GB at the time of writing.

### Setup ###

#### Bitcoin ruby ####
Start by setting up a postgres server and installing bitcoin-ruby. You can speed up the intial import of the blockchain data by using a recent dump from [webtc.com](http://dumps.webbtc.com/). Once installed make sure you run bitcoin_node to keep your blockchain up-to-date.

#### Rails project ####

Start by updating your database in config/database.yml, this can either choose to share these details with the bitcoin-ruby database or keep them seperately. Next up set the connection to your bitcoin-ruby database in development.rb and production.rb.

#### Cronjobs ####

In order to keep the data up-to-date you can run the following jobs: 

```bash
  bundle exec rake mastercoin:check_for_invalid
  bundle exec rake mastercoin:parse_exodus
```

The first one checks to see which payments might be invalid the second one parses new transactions.

#### Transaction relaying ####
If you want to relay transactions from the ruby thin-client wallet you can start the relay script by issuing ```bundle exec rake bitcoin:relayer```. However in most cases this is not needed.
