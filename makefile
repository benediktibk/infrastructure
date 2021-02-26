#!/usr/bin/make -f

default: clean all

clean:
	rm -Rf servers/valheim/build

all: environment-check images

images:
	mkdir -p servers/valheim/build
	docker build --build-arg BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/database-server servers/database-server	
	docker build -t benediktschmidt.at/mssql-client servers/mssql-client
	docker build -t benediktschmidt.at/me servers/homepage
	cp -R ${BENEDIKTSCHMIDT_AT_VALHEIM_INSTALLATION_PATH}/* servers/valheim/build/
	docker build -t benediktschmidt.at/valheim servers/valheim
		
run: environment-check
	docker-compose up
	
environment-check:
ifndef BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD
	$(error BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD is undefined)
endif
ifndef BENEDIKTSCHMIDT_AT_CA_PRIVATE_KEYS
	$(error BENEDIKTSCHMIDT_AT_CA_PRIVATE_KEYS is undefined)
endif
ifndef BENEDIKTSCHMIDT_AT_VALHEIM_INSTALLATION_PATH
	$(error BENEDIKTSCHMIDT_AT_VALHEIM_INSTALLATION_PATH is undefined)
endif
ifndef BENEDIKTSCHMIDT_AT_VALHEIM_SERVER_NAME
	$(error BENEDIKTSCHMIDT_AT_VALHEIM_SERVER_NAME is undefined)
endif
ifndef BENEDIKTSCHMIDT_AT_VALHEIM_SERVER_PASSWORD
	$(error BENEDIKTSCHMIDT_AT_VALHEIM_SERVER_PASSWORD is undefined)
endif
	
.PHONY: environment-check images
