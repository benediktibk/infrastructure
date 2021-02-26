#!/usr/bin/make -f

default: clean all

clean:

all: environment-check database-server mssql-client

database-server:
	docker build --build-arg BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/database-server database-server	

mssql-client:
	docker build -t benediktschmidt.at/mssql-client mssql-client
		
run: environment-check
	docker-compose up
	
environment-check:
ifndef BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD
	$(error BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD is undefined)
endif
ifndef BENEDIKTSCHMIDT_AT_CA_PRIVATE_KEYS
	$(error BENEDIKTSCHMIDT_AT_CA_PRIVATE_KEYS is undefined)
endif
	
.PHONY: environment-check mssql-client database-server
