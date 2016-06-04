# StockDB

日本の株式情報を収集し、ローカルのデータベースに取り込むツールセットです。
以下のデータを収集可能です。

- 日本株式のレートデータ
  - Quandl, k-db.comからの取得に対応しています。
- 信用取引残高
  - 日証金から日ごとのデータを取得します。

## Tables

![tables](tables.png)

## Pre-Requirements

```sh
$ git --version
git version 1.8.3.1
$ docker -v
Docker version 1.10.2, build c3959b1
$ docker-compose -v
docker-compose version 1.6.2, build 4d72027
```

## Usage

```sh
$ git clone https://github.com/unageanu/stock-db.git
$ cd stock-db
$ vi .env # Set POSTGRES_PASSWORD, QUANDL_API_KEY ..etc..
          # See the example below:
---
POSTGRES_USER=postgres
POSTGRES_PASSWORD=mysecretpassword
QUANDL_API_KEY=myquandlapikey
QUANDL_API_VERSION=2015-04-09
---
$ docker-compose up -d # PostgreSQL を起動

$ bundle install

# 日本株式のレートデータの取り込み
$ bundle exec ruby -I src ./src/quandl_importer.rb
# or
$ bundle exec ruby -I src ./src/k_db_importer.rb 2016-01-01 2016-03-01

# 信用取引残高
$ bundle exec ruby -I src ./src/stock_lending_importer.rb 2016-01-01 2016-03-01
```


## License

[MIT license](//datatables.net/license)
