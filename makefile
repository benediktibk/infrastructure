#!/usr/bin/make -f

default: clean all

clean:

all: environment database-server mssql-client

database-server:
	docker build --build-arg BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/database-server database-server	

mssql-client:
	docker build --build-arg BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/mssql-client mssql-client
	
environment:
	source ~/environment.benediktschmidt.at
	
run:
	docker-compose up
	
.PHONY: environment mssql-client database-server
