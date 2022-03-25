#!/usr/bin/make -f

SECRETSDECRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in secrets.tar.gz.enc | tar xz
SECRETSENCRYPT := openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in build/secrets.tar.gz -out secrets.tar.gz.enc
COMMONDEPS := build/guard Makefile build/secrets/guard
ENVIRONMENTS := sql valheim corona reverse-proxy vpn firewall postgres zabbix-server zabbix-frontend cron-passwords cron-volume-backup cron-storage-backup google-drive-triest cron-triest-backup
ENVIRONMENTFILES := $(addprefix build/environments/,$(addsuffix .env,$(ENVIRONMENTS)))
IMAGENAMES := valheim database-server homepage corona-viewer corona-updater corona-init reverse-proxy downloads vpn firewall dc network-util certbot amongus postgres zabbix-server zabbix-frontend downloads-share cron-passwords cron-volume-backup cron-storage-backup google-drive-triest cron-triest-backup
IMAGEIDS := $(addprefix build/,$(addsuffix -id.txt,$(IMAGENAMES)))
IMAGEPUSHEDIDS := $(addprefix build/,$(addsuffix -pushed-id.txt,$(IMAGENAMES)))
VOLUMES := sql corona valheim downloads webcertificates dc acme letsencrypt proxycache postgres googledrivetriest
VPNCLIENTCONFIGS = $(shell find servers/vpn/ -iname *.location.benediktschmidt.at)
VALHEIMDIRECTORY = ~/.steam/debian-installation/steamapps/common/valheim_dedicated_server
VALHEIMFILES = $(shell find $(VALHEIMDIRECTORY))
HOMEPAGEFILES = $(shell find servers/homepage)

CREATEVOLUMES := for volume in $(VOLUMES); do echo "creating volume $$volume"; docker volume create "$$volume"; done;
DELETEVOLUMES := if [ ! -z "$(shell docker ps -a -q)" ]; then docker rm -f $(shell docker ps -a -q); fi; docker volume rm $(VOLUMES)
DOCKERCOMPOSECORONAINIT := docker-compose --project-name infrastructure-init -f compose-files/corona-init.yaml up --abort-on-container-exit
DOCKERCOMPOSESERVER := docker-compose --project-name infrastructure -f compose-files/server.yaml up

############ general

all: $(IMAGEPUSHEDIDS) $(ENVIRONMENTFILES) tests

clean:
	git clean -xdff
	
run: $(IMAGEIDS) $(ENVIRONMENTFILES)
	$(DOCKERCOMPOSESERVER)

deploy-update: $(ENVIRONMENTFILES) $(IMAGEPUSHEDIDS)
	ansible-playbook playbooks/dockerhost-deploy-update.yaml

deploy: $(ENVIRONMENTFILES) $(IMAGEPUSHEDIDS)
	ansible-playbook playbooks/dockerhost-deploy.yaml
	
data-clean: $(ENVIRONMENTFILES)
	$(DELETEVOLUMES)
	
data-init: $(IMAGEIDS) $(ENVIRONMENTFILES)
	$(CREATEVOLUMES)
	$(DOCKERCOMPOSECORONAINIT)

build/guard: Makefile
	mkdir -p build
	mkdir -p build/servers
	mkdir -p build/servers/database
	mkdir -p build/servers/homepage
	mkdir -p build/servers/homepage/bin
	mkdir -p build/servers/corona
	mkdir -p build/servers/corona/viewer
	mkdir -p build/servers/corona/viewer/bin
	mkdir -p build/servers/corona/updater
	mkdir -p build/servers/corona/updater/bin
	mkdir -p build/servers/corona/init
	mkdir -p build/servers/corona/init/bin
	mkdir -p build/servers/valheim
	mkdir -p build/servers/valheim/bin
	mkdir -p build/servers/reverse-proxy
	mkdir -p build/servers/downloads
	mkdir -p build/servers/vpn
	mkdir -p build/servers/firewall
	mkdir -p build/servers/dc
	mkdir -p build/servers/network-util
	mkdir -p build/servers/certbot
	mkdir -p build/servers/amongus
	mkdir -p build/servers/postgres
	mkdir -p build/servers/zabbix-server
	mkdir -p build/servers/zabbix-frontend
	mkdir -p build/servers/downloads-share
	mkdir -p build/servers/cron-passwords
	mkdir -p build/servers/cron-volume-backup
	mkdir -p build/servers/cron-storage-backup
	mkdir -p build/servers/google-drive-triest
	mkdir -p build/servers/cron-triest-backup
	mkdir -p build/environments
	touch $@

tests:
	cd servers/corona/Corona && dotnet test
	
.PHONY: all clean data-init data-clean data-clean run-local deploy-update secrets-encrypt build/secrets.tar.gz tests
	 
############ container
	
build/valheim-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-valheim servers/valheim/start_server.sh $(VALHEIMFILES)
	cp dockerfiles/Dockerfile-valheim build/servers/valheim/Dockerfile
	cp servers/valheim/start_server.sh build/servers/valheim/start_server.sh
	cp -R $(VALHEIMDIRECTORY)/* build/servers/valheim/bin/
	docker build -t benediktibk/valheim build/servers/valheim
	docker images --format "{{.ID}}" benediktibk/valheim > $@
	
build/database-server-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-database
	cp dockerfiles/Dockerfile-database build/servers/database/Dockerfile
	docker build -t benediktibk/database-server build/servers/database
	docker images --format "{{.ID}}" benediktibk/database-server > $@
	
build/homepage-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-homepage $(HOMEPAGEFILES)
	cp dockerfiles/Dockerfile-homepage build/servers/homepage/Dockerfile
	cp -R servers/homepage/me build/servers/homepage/bin
	docker build -t benediktibk/homepage build/servers/homepage
	docker images --format "{{.ID}}" benediktibk/homepage > $@
	
build/corona-viewer-id.txt: $(COMMONDEPS) build/servers/corona/viewer/bin/CoronaSpreadViewer.dll dockerfiles/Dockerfile-corona-viewer
	cp dockerfiles/Dockerfile-corona-viewer build/servers/corona/viewer/Dockerfile
	docker build -t benediktibk/corona-viewer build/servers/corona/viewer
	docker images --format "{{.ID}}" benediktibk/corona-viewer > $@

build/corona-updater-id.txt: $(COMMONDEPS) build/servers/corona/updater/bin/Updater.dll dockerfiles/Dockerfile-corona-updater scripts/corona-updater.sh
	cp dockerfiles/Dockerfile-corona-updater build/servers/corona/updater/Dockerfile
	cp scripts/corona-updater.sh build/servers/corona/updater/corona-updater.sh
	docker build -t benediktibk/corona-updater build/servers/corona/updater
	docker images --format "{{.ID}}" benediktibk/corona-updater > $@

build/corona-init-id.txt: $(COMMONDEPS) build/servers/corona/init/bin/Updater.dll dockerfiles/Dockerfile-corona-init scripts/corona-init.sh
	cp dockerfiles/Dockerfile-corona-init build/servers/corona/init/Dockerfile
	cp scripts/corona-init.sh build/servers/corona/init/corona-init.sh
	docker build -t benediktibk/corona-init build/servers/corona/init
	docker images --format "{{.ID}}" benediktibk/corona-init > $@
	
build/reverse-proxy-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-reverse-proxy servers/reverse-proxy/default.conf.template servers/reverse-proxy/nginx-start.sh servers/reverse-proxy/nginx.conf
	cp dockerfiles/Dockerfile-reverse-proxy build/servers/reverse-proxy/Dockerfile
	cp servers/reverse-proxy/default.conf.template build/servers/reverse-proxy/
	cp servers/reverse-proxy/nginx.conf build/servers/reverse-proxy/
	cp servers/reverse-proxy/nginx-start.sh build/servers/reverse-proxy/nginx-start.sh
	cp build/secrets/ca/root_ca.crt build/servers/reverse-proxy/root_ca.crt
	docker build -t benediktibk/reverse-proxy build/servers/reverse-proxy
	docker images --format "{{.ID}}" benediktibk/reverse-proxy > $@	
	
build/downloads-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-downloads servers/downloads/default.conf
	cp dockerfiles/Dockerfile-downloads build/servers/downloads/Dockerfile
	cp servers/downloads/default.conf build/servers/downloads/default.conf
	docker build -t benediktibk/downloads build/servers/downloads
	docker images --format "{{.ID}}" benediktibk/downloads > $@
	
build/vpn-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-vpn servers/vpn/server.conf.template servers/vpn/openvpn-start.sh $(VPNCLIENTCONFIGS)
	cp dockerfiles/Dockerfile-vpn build/servers/vpn/Dockerfile
	cp servers/vpn/server.conf.template build/servers/vpn/
	cp servers/vpn/openvpn-start.sh build/servers/vpn
	cp $(VPNCLIENTCONFIGS) build/servers/vpn/
	docker build -t benediktibk/vpn build/servers/vpn
	docker images --format "{{.ID}}" benediktibk/vpn > $@

build/firewall-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-firewall servers/firewall/firewall.sh
	cp dockerfiles/Dockerfile-firewall build/servers/firewall/Dockerfile
	cp servers/firewall/firewall.sh build/servers/firewall/
	docker build -t benediktibk/firewall build/servers/firewall
	docker images --format "{{.ID}}" benediktibk/firewall > $@

build/dc-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-dc servers/dc/start.sh servers/dc/smb.conf servers/dc/krb5.conf servers/dc/resolv.conf
	cp dockerfiles/Dockerfile-dc build/servers/dc/Dockerfile
	cp servers/dc/start.sh build/servers/dc/
	cp servers/dc/smb.conf build/servers/dc/
	cp servers/dc/krb5.conf build/servers/dc/
	cp servers/dc/resolv.conf build/servers/dc/
	docker build -t benediktibk/dc build/servers/dc
	docker images --format "{{.ID}}" benediktibk/dc > $@

build/network-util-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-network-util servers/network-util/endless-loop.sh
	cp dockerfiles/Dockerfile-network-util build/servers/network-util/Dockerfile
	cp servers/network-util/endless-loop.sh build/servers/network-util/
	docker build -t benediktibk/network-util build/servers/network-util
	docker images --format "{{.ID}}" benediktibk/network-util > $@

build/certbot-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-certbot servers/certbot/certbot.sh
	cp dockerfiles/Dockerfile-certbot build/servers/certbot/Dockerfile
	cp servers/certbot/certbot.sh build/servers/certbot/
	docker build -t benediktibk/certbot build/servers/certbot
	docker images --format "{{.ID}}" benediktibk/certbot > $@

build/amongus-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-amongus servers/amongus/config.json
	cp dockerfiles/Dockerfile-amongus build/servers/amongus/Dockerfile
	cp servers/amongus/config.json build/servers/amongus/
	docker build -t benediktibk/amongus build/servers/amongus
	docker images --format "{{.ID}}" benediktibk/amongus > $@

build/postgres-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-postgres servers/postgres/init-db-zabbix.sh
	cp dockerfiles/Dockerfile-postgres build/servers/postgres/Dockerfile
	cp servers/postgres/init-db-zabbix.sh build/servers/postgres/
	docker build -t benediktibk/postgres build/servers/postgres
	docker images --format "{{.ID}}" benediktibk/postgres > $@

build/zabbix-server-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-zabbix-server
	cp dockerfiles/Dockerfile-zabbix-server build/servers/zabbix-server/Dockerfile
	docker build -t benediktibk/zabbix-server build/servers/zabbix-server
	docker images --format "{{.ID}}" benediktibk/zabbix-server > $@

build/zabbix-frontend-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-zabbix-frontend
	cp dockerfiles/Dockerfile-zabbix-frontend build/servers/zabbix-frontend/Dockerfile
	docker build -t benediktibk/zabbix-frontend build/servers/zabbix-frontend
	docker images --format "{{.ID}}" benediktibk/zabbix-frontend > $@

build/downloads-share-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-downloads-share servers/downloads-share/start.sh servers/downloads-share/smb.conf
	cp dockerfiles/Dockerfile-downloads-share build/servers/downloads-share/Dockerfile
	cp servers/downloads-share/start.sh build/servers/downloads-share/
	cp servers/downloads-share/smb.conf build/servers/downloads-share/
	docker build -t benediktibk/downloads-share build/servers/downloads-share
	docker images --format "{{.ID}}" benediktibk/downloads-share > $@

build/cron-passwords-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-cron-passwords servers/cron-passwords/copy-passwords.sh servers/cron-passwords/cronjobs
	cp dockerfiles/Dockerfile-cron-passwords build/servers/cron-passwords/Dockerfile
	cp servers/cron-passwords/copy-passwords.sh build/servers/cron-passwords/
	cp servers/cron-passwords/cronjobs build/servers/cron-passwords/
	docker build -t benediktibk/cron-passwords build/servers/cron-passwords
	docker images --format "{{.ID}}" benediktibk/cron-passwords > $@

build/cron-volume-backup-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-cron-volume-backup servers/cron-volume-backup/backup-volumes.sh servers/cron-volume-backup/cronjobs
	cp dockerfiles/Dockerfile-cron-volume-backup build/servers/cron-volume-backup/Dockerfile
	cp servers/cron-volume-backup/backup-volumes.sh build/servers/cron-volume-backup/
	cp servers/cron-volume-backup/cronjobs build/servers/cron-volume-backup/
	docker build -t benediktibk/cron-volume-backup build/servers/cron-volume-backup
	docker images --format "{{.ID}}" benediktibk/cron-volume-backup > $@

build/cron-storage-backup-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-cron-storage-backup servers/cron-storage-backup/backup-storage.sh servers/cron-storage-backup/cronjobs
	cp dockerfiles/Dockerfile-cron-storage-backup build/servers/cron-storage-backup/Dockerfile
	cp servers/cron-storage-backup/backup-storage.sh build/servers/cron-storage-backup/
	cp servers/cron-storage-backup/cronjobs build/servers/cron-storage-backup/
	docker build -t benediktibk/cron-storage-backup build/servers/cron-storage-backup
	docker images --format "{{.ID}}" benediktibk/cron-storage-backup > $@

build/google-drive-triest-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-google-drive-triest servers/google-drive-triest/start.sh servers/google-drive-triest/rclone.conf.template servers/google-drive-triest/cronjobs
	cp dockerfiles/Dockerfile-google-drive-triest build/servers/google-drive-triest/Dockerfile
	cp servers/google-drive-triest/start.sh build/servers/google-drive-triest/
	cp servers/google-drive-triest/rclone.conf.template build/servers/google-drive-triest/
	cp servers/google-drive-triest/cronjobs build/servers/google-drive-triest/
	docker build -t benediktibk/google-drive-triest build/servers/google-drive-triest
	docker images --format "{{.ID}}" benediktibk/google-drive-triest > $@

build/cron-triest-backup-id.txt: $(COMMONDEPS) dockerfiles/Dockerfile-cron-triest-backup servers/cron-triest-backup/backup-triest.sh servers/cron-triest-backup/cronjobs
	cp dockerfiles/Dockerfile-cron-triest-backup build/servers/cron-triest-backup/Dockerfile
	cp servers/cron-triest-backup/backup-triest.sh build/servers/cron-triest-backup/
	cp servers/cron-triest-backup/cronjobs build/servers/cron-triest-backup/
	docker build -t benediktibk/cron-triest-backup build/servers/cron-triest-backup
	docker images --format "{{.ID}}" benediktibk/cron-triest-backup > $@
	
build/%-pushed-id.txt: build/%-id.txt
	rm -f $@
	docker push benediktibk/$*
	touch $@

############ environment definitions
	
build/environments/sql.env: environments/sql.env.in build/secrets/passwords/db_sa $(COMMONDEPS)
	cp $< $@
	$(eval SA_PASSWORD := $(shell cat build/secrets/passwords/db_sa))
	sed -i "s/##SA_PASSWORD##/${SA_PASSWORD}/g" $@

build/environments/valheim.env: environments/valheim.env.in build/secrets/passwords/valheim $(COMMONDEPS)
	cp $< $@
	$(eval SERVER_PASSWORD := $(shell cat build/secrets/passwords/valheim))
	sed -i "s/##SERVER_PASSWORD##/$(SERVER_PASSWORD)/g" $@

build/environments/corona.env: environments/corona.env.in build/secrets/passwords/db_corona $(COMMONDEPS)
	cp $< $@
	$(eval DBCORONAPASSWORD := $(shell cat build/secrets/passwords/db_corona))
	sed -i "s/##DBCORONAPASSWORD##/${DBCORONAPASSWORD}/g" $@

build/environments/postgres.env: environments/postgres.env.in build/secrets/passwords/db_zabbix build/secrets/passwords/postgres $(COMMONDEPS)
	cp $< $@
	$(eval POSTGRES_PASSWORD := $(shell cat build/secrets/passwords/postgres))
	$(eval ZABBIX_DB_PASSWORD := $(shell cat build/secrets/passwords/db_zabbix))
	sed -i "s/##POSTGRES_PASSWORD##/${POSTGRES_PASSWORD}/g" $@
	sed -i "s/##ZABBIX_DB_PASSWORD##/${ZABBIX_DB_PASSWORD}/g" $@

build/environments/zabbix-server.env: environments/zabbix-server.env.in build/secrets/passwords/db_zabbix $(COMMONDEPS)
	cp $< $@
	$(eval ZABBIX_DB_PASSWORD := $(shell cat build/secrets/passwords/db_zabbix))
	sed -i "s/##ZABBIX_DB_PASSWORD##/${ZABBIX_DB_PASSWORD}/g" $@

build/environments/zabbix-frontend.env: environments/zabbix-frontend.env.in build/secrets/passwords/db_zabbix $(COMMONDEPS)
	cp $< $@
	$(eval ZABBIX_DB_PASSWORD := $(shell cat build/secrets/passwords/db_zabbix))
	sed -i "s/##ZABBIX_DB_PASSWORD##/${ZABBIX_DB_PASSWORD}/g" $@

build/environments/cron-passwords.env: environments/cron-passwords.env.in build/secrets/passwords/system-cron-passwords $(COMMONDEPS)
	cp $< $@
	$(eval DOMAINPASSWORD := $(shell cat build/secrets/passwords/system-cron-passwords))
	sed -i "s/##DOMAINPASSWORD##/${DOMAINPASSWORD}/g" $@

build/environments/cron-volume-backup.env: environments/cron-volume-backup.env.in build/secrets/passwords/system-cron-volume $(COMMONDEPS)
	cp $< $@
	$(eval DOMAINPASSWORD := $(shell cat build/secrets/passwords/system-cron-volume))
	sed -i "s/##DOMAINPASSWORD##/${DOMAINPASSWORD}/g" $@

build/environments/cron-storage-backup.env: environments/cron-storage-backup.env.in build/secrets/passwords/system-cron-storage $(COMMONDEPS)
	cp $< $@
	$(eval DOMAINPASSWORD := $(shell cat build/secrets/passwords/system-cron-storage))
	sed -i "s/##DOMAINPASSWORD##/${DOMAINPASSWORD}/g" $@

build/environments/google-drive-triest.env: environments/google-drive-triest.env.in build/secrets/passwords/google-drive-client-secret $(COMMONDEPS)
	cp $< $@
	$(eval GOOGLEDRIVECLIENTSECRET := $(shell cat build/secrets/passwords/google-drive-client-secret))
	sed -i "s/##GOOGLEDRIVECLIENTSECRET##/${GOOGLEDRIVECLIENTSECRET}/g" $@

build/environments/cron-triest-backup.env: environments/cron-triest-backup.env.in build/secrets/passwords/system-cron-triest $(COMMONDEPS)
	cp $< $@
	$(eval DOMAINPASSWORD := $(shell cat build/secrets/passwords/system-cron-triest))
	sed -i "s/##DOMAINPASSWORD##/${DOMAINPASSWORD}/g" $@

build/environments/%.env: environments/%.env
	cp $< $@


############ apps

build/servers/corona/viewer/bin/CoronaSpreadViewer.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/CoronaSpreadViewer --output build/servers/corona/viewer/bin --configuration Release --runtime linux-x64
	touch $@
	
build/servers/corona/updater/bin/Updater.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/Updater --output build/servers/corona/updater/bin --configuration Release --runtime linux-x64
	touch $@

build/servers/corona/init/bin/Updater.dll: $(COMMONDEPS) $(shell find servers/corona/Corona -type f -not -path "*/bin/*" -not -path "*/obj/*" -name "*")
	dotnet publish servers/corona/Corona/Updater --output build/servers/corona/init/bin --configuration Release --runtime linux-x64
	touch $@

	
############ secrets

build/secrets/guard: secrets.tar.gz.enc
	mkdir -p build
	mkdir -p build/secrets
	$(SECRETSDECRYPT)
	touch $@

secrets-encrypt: Makefile build/secrets.tar.gz
	$(SECRETSENCRYPT)

build/secrets.tar.gz: Makefile
	rm -f $@
	tar -czvf $@ build/secrets

build/secrets/passwords/db_sa: build/secrets/guard

build/secrets/passwords/db_corona: build/secrets/guard

build/secrets/passwords/valheim: build/secrets/guard

build/secrets/passwords/postgres: build/secrets/guard

build/secrets/passwords/db_zabbix: build/secrets/guard

build/secrets/passwords/system-cron-passwords: build/secrets/guard

build/secrets/passwords/system-cron-volume: build/secrets/guard

build/secrets/passwords/system-cron-storage: build/secrets/guard

build/secrets/passwords/google-drive-triest-credentials.json: build/secrets/guard

build/secrets/passwords/google-drive-client-secret: build/secrets/guard

build/secrets/passwords/system-cron-triest: build/secrets/guard