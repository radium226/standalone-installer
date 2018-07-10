vagrant-box-update:
	cd "./vagrant" ; \
	vagrant box update

vagrant-up:
	cd "./vagrant" ; \
	vagrant up --provision

vagrant-destroy:
	cd "./vagrant" ; \
	vagrant destroy --force

vagrant-ssh-virtual-machine-01:
	cd "./vagrant" ; \
	vagrant ssh "virtual-machine-01"

vagrant-ssh-virtual-machine-02:
	cd "./vagrant" ; \
	vagrant ssh "virtual-machine-02"

download-pypy:
	mkdir -p "./vendors/pypy" ; \
	cd "./vendors/pypy" ; \
	test -f "./pypy3.5-6.0.0-linux_x86_64-portable.tar.bz2" || \
		wget "https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.5-6.0.0-linux_x86_64-portable.tar.bz2" \
			-O "./pypy3.5-6.0.0-linux_x86_64-portable.tar.bz2"

download-python-wheels:
	cd "./vendors" ; \
	test -d "./.python-wheels-virtualenv" || \
		virtualenv "./.python-wheels-virtualenv" ; \
	source "./.python-wheels-virtualenv/bin/activate" ; \
	mkdir -p "./python-wheels" ; \
	cd "./python-wheels" ; \
	pip download -r "../../requirements.txt"

download-python-sources:
	mkdir -p "./vendors/python-sources" ; \
	cd "./vendors/python-sources" ; \
	test -f "./cryptography-2.2.2.tar.gz" || wget "https://files.pythonhosted.org/packages/ec/b2/faa78c1ab928d2b2c634c8b41ff1181f0abdd9adf9193211bd606ffa57e2/cryptography-2.2.2.tar.gz" -O "./cryptography-2.2.2.tar.gz" ; \
	test -f "./bcrypt-3.1.4.tar.gz" || wget "https://files.pythonhosted.org/packages/f3/ec/bb6b384b5134fd881b91b6aa3a88ccddaad0103857760711a5ab8c799358/bcrypt-3.1.4.tar.gz" -O "./bcrypt-3.1.4.tar.gz" ; \
	test -f "./PyNaCl-1.2.1.tar.gz" || wget "https://files.pythonhosted.org/packages/08/19/cf56e60efd122fa6d2228118a9b345455b13ffe16a14be81d025b03b261f/PyNaCl-1.2.1.tar.gz" -O "./PyNaCl-1.2.1.tar.gz"


download-vendors: download-pypy download-python-wheels download-python-sources

create-archive: download-vendors
	tar -czf "./archive.tar.gz" \
		"./scripts" \
		"./ansible" \
		"./vendors/pypy" \
		"./vendors/python-sources" \
		"./vendors/python-wheels"

embbed-archive: create-archive
	cat "./archive.tar.gz" | base64 >"./archive.tar.gz.base64" ; \
	cat "./provision-HEAD" "./archive.tar.gz.base64" >"./provision" ; \
	chmod +x "./provision"

package: embbed-archive

generate-vagrant-inventory: vagrant-up
	mkdir -p "./ansible/inventories" ; \
	cd "./ansible/inventories" ; \
	"../../vagrant/ansible-inventory.py" >"./vagrant.ini"

# sudo -E unshare -n sudo -E -u ${USER}
test: generate-vagrant-inventory package
	./provision --environment="vagrant"
