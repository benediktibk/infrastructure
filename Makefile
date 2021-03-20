#!/usr/bin/make -f

all: environment-check images

clean:
	rm -Rf servers/valheim/build

images:
	mkdir -p servers/valheim/build
	cp -R ${BENEDIKTSCHMIDT_AT_VALHEIM_INSTALLATION_PATH}/* servers/valheim/build/
	docker build -t benediktschmidt.at/valheim servers/valheim
	docker build --build-arg BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD=${BENEDIKTSCHMIDT_AT_SQL_SA_PASSWORD} -t benediktschmidt.at/database-server servers/database-server	
	docker build -t benediktschmidt.at/mssql-client servers/mssql-client
	docker build -t benediktschmidt.at/me servers/homepage
	mkdir -p servers/tester/build
	cp docker-compose.yml servers/tester/build/
	cp environment servers/tester/build/
	docker build -t benediktschmidt.at/tester servers/tester
		
run-tester: images environment-check
	docker run -v /var/run/docker.sock:/var/run/docker.sock benediktschmidt.at/tester
	
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
