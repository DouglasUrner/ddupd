BINDIR=/usr/local/bin
CONFDIR=/etc
LAUNCH_DAEMONS=/Library/LaunchDaemons
PLIST=com.canishe.ddupd.plist

install: $(BINDIR)/ddupd $(CONFDIR)/ddupd.conf $(LAUNCH_DAEMONS)/$(PLIST)

$(BINDIR)/ddupd: ddupd.sh
	sudo mkdir -p $(BINDIR)
	sudo cp $? $@
	sudo chown root:admin $@

$(CONFDIR)/ddupd.conf: ddupd.conf
	sudo mkdir -p $(CONFDIR)
	sudo cp $? $@
	sudo chmod 400 $@
	sudo chown root:admin $@

$(LAUNCH_DAEMONS)/$(PLIST): $(PLIST)
	sudo cp $? $@
	sudo chown root:admin $@
	sudo launchctl load $@
