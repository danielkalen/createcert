global.Promise = require 'bluebird'
fs = require 'fs-jetpack'
createCert = require 'create-cert'
execa = require 'execa'
args = require('minimist')(process.argv.slice(2))
domain = args._[0]
name = args._[1]
SSL_DIR = "#{process.env.HOME}/.ssl"
FILES = 
	key: "#{SSL_DIR}/#{name}.key.pem"
	cert: "#{SSL_DIR}/#{name}.cert.pem"
	caCert: "#{SSL_DIR}/#{name}.caCert.pem"
	sslconf: "#{__dirname}/temp-openssl.cnf"

if args._.length < 2
	console.error 'requires 2 args'
	process.exit(1)

Promise.resolve(domain)
	.then ()-> fs.readAsync '/System/Library/OpenSSL/openssl.cnf'
	.then (opensslConf)-> fs.writeAsync FILES.sslconf, "#{opensslConf}\n[SAN]\nsubjectAltName=DNS:#{domain}"
	.then ()->
		execa 'openssl', [
			'req'
			'-newkey', 'rsa:2048'
			'-x509'
			'-nodes'
			'-keyout', FILES.key
			'-new'
			'-out', FILES.cert
			'-subj', "/CN=#{domain}"
			'-reqexts', 'SAN'
			'-extensions', 'SAN'
			'-config', FILES.sslconf
			'-sha256'
			'-days', 3650
		], stdio:'inherit'
	.then ()->
		console.log(FILES.key)
		console.log(FILES.cert)
		console.log(FILES.caCert)
	.then ()->
		execa('open', ['/Applications/Utilities/Keychain\ Access.app', FILES.cert], stdio:'inherit')