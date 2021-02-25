#!/usr/bin/make -f

default: clean all

clean:

all: database-server mssql-client

database-server:
	docker build -t benediktschmidt.at/database-server database-server	

mssql-client:
	docker build -t benediktschmidt.at/mssql-client mssql-client
	
run:
	docker run -d benediktschmidt.at/database-server
	docker run -it benediktschmidt.at/mssql-client
	
.PHONY: mssql-client database-server
