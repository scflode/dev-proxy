# Domains

This document explains the steps needed to make new domains reachable. There 
are two methods:

- Add an entry to `/etc/hosts` for each domain
- Setup `dnsmasq` to map `*.localhost` to `127.0.0.1`

## Setup steps

### Add domains to `/etc/hosts/`

Although some browsers (like Chrome, Edge) are able to automatically point
`*.localhost` to `127.0.0.1` or `localhost` others like Safari are not. Also CLI
tools like `curl`, `ping` etc. cannot resolve these addresses.

Open your `/etc/hosts` file and add the following:

```
127.0.0.1 		my_app.domain.localhost my_other_app.domain.localhost
```

### Use dnsmasq instead hosts file (Homebrew)

To setup a real DNS server you can use `dnsmasq`.

The advantage is that for new domains no other step is needed than to add it 
to the project (see "Add new services").

For macOS use the following commands in order:

```
# Install dnsmasq via Homebrew
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc/
# Configure `.localhost` resolving
echo 'address=/.localhost/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
echo 'port=53' >> $(brew --prefix)/etc/dnsmasq.conf
# Start persistent service
sudo brew services start dnsmasq
sudo mkdir -v /etc/resolver
# Add the nameserver to the resolver for `.localhost` domains
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/localhost'
scutil --dns
```

> For details and discussion see https://gist.github.com/ogrrd/5831371

