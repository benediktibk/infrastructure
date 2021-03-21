#!/usr/bin/make -f

SECRETSENCRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in secrets.tar.gz.enc | tar xz

############ genral

all: images

clean:
	rm -Rf servers/valheim/build
	rm -Rf servers/tester/build
	rm -Rf servers/corona/build
	rm -Rf build
	cd servers/corona/Corona && dotnet clean
	
run-tester: images
	docker run --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock benediktschmidt.at/tester
	
clean-data:
	docker volume rm sqldata
	
init-data: servers/corona/Corona/Updater/bin/Release/netcoreapp5.0/Updater.dll build/database-server-id.txt build/sql.env
	docker volume create sqldata
	./initialize-database.sh
	
	
############ container	

images: build/valheim-id.txt build/database-server-id.txt build/homepage-id.txt build/tester-id.txt build/corona-id.txt
	
build/valheim-id.txt: servers/valheim/Dockerfile
	mkdir -p build
	mkdir -p servers/valheim/build
	cp -R ~/.local/share/Steam/steamapps/common/Valheim\ dedicated\ server/* servers/valheim/build/
	docker build -t benediktschmidt.at/valheim servers/valheim
	docker images --format "{{.ID}}" benediktschmidt.at/valheim > $@
	
build/database-server-id.txt: servers/database-server/Dockerfile
	mkdir -p build
	docker build -t benediktschmidt.at/database-server servers/database-server
	docker images --format "{{.ID}}" benediktschmidt.at/database-server > $@
	
build/homepage-id.txt: servers/homepage/Dockerfile
	mkdir -p build
	docker build -t benediktschmidt.at/me servers/homepage
	docker images --format "{{.ID}}" benediktschmidt.at/homepage > $@
	
build/tester-id.txt: servers/tester/Dockerfile docker-compose.yml build/sql.env build/valheim.env build/corona.env
	mkdir -p build
	mkdir -p servers/tester/build
	cp docker-compose.yml servers/tester/build/
	cp build/*.env servers/tester/build/
	docker build -t benediktschmidt.at/tester servers/tester
	docker images --format "{{.ID}}" benediktschmidt.at/tester > $@
	
build/corona-id.txt: servers/corona/Dockerfile servers/corona/Corona/CoronaSpreadViewer/bin/Release/netcoreapp5.0/CoronaSpreadViewer.dll
	mkdir -p build
	docker build -t benediktschmidt.at/corona servers/corona
	docker images --format "{{.ID}}" benediktschmidt.at/corona > $@
	

############ environment definitions
	
build/sql.env: sql.env.in build/secrets/passwords/db_sa
	cp $< $@
	$(eval SA_PASSWORD := $(shell cat build/secrets/passwords/db_sa))
	sed -i "s/##SA_PASSWORD##/${SA_PASSWORD}/g" $@

build/valheim.env: valheim.env.in build/secrets/passwords/valheim
	cp $< $@
	$(eval SERVER_PASSWORD := $(shell cat build/secrets/passwords/valheim))
	sed -i "s/##SERVER_PASSWORD##/$(SERVER_PASSWORD)/g" $@

build/corona.env: corona.env.in build/secrets/passwords/db_corona
	cp $< $@
	$(eval DBCORONAPASSWORD := $(shell cat build/secrets/passwords/db_corona))
	sed -i "s/##DBCORONAPASSWORD##/${DBCORONAPASSWORD}/g" $@


############ apps

servers/corona/Corona/CoronaSpreadViewer/bin/Release/netcoreapp5.0/CoronaSpreadViewer.dll: $(shell find servers/corona/Corona/ -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*") servers/corona/build/appsettings.json
	cd servers/corona/Corona/CoronaSpreadViewer && dotnet build --configuration Release
	cp servers/corona/build/appsettings.json servers/corona/Corona/CoronaSpreadViewer/bin/Release/netcoreapp5.0/
	touch $@
	
servers/corona/Corona/Updater/bin/Release/netcoreapp5.0/Updater.dll: $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*") servers/corona/build/appsettings.json
	cd servers/corona/Corona/Updater && dotnet build --configuration Release
	cp servers/corona/build/appsettings.json servers/corona/Corona/Updater/bin/Release/netcoreapp5.0/
	touch $@

	
############ secrets
	
build/secrets/passwords/db_sa: secrets.tar.gz.enc
	$(SECRETSENCRYPT)
	touch --no-create build/secrets/passwords/*
	
build/secrets/passwords/db_corona: secrets.tar.gz.enc
	$(SECRETSENCRYPT)
	touch --no-create build/secrets/passwords/*
	
build/secrets/passwords/valheim: secrets.tar.gz.enc
	$(SECRETSENCRYPT)
	touch --no-create build/secrets/passwords/*
