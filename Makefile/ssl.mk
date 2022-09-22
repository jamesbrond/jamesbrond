# required makefiles:
# - misc.mk

# required variables:
#

# optional variables:
# - OPENSSL

OPENSSL ?= openssl

# call ssl_cert,HOSTNAME,KEY_OUTPUT_FILE,CERT_OUTPUT_FILE,SUBJECT
define ssl_cert
	@$(call prompt-info,Generate SSL certifiacte for $(1))
	@$(OPENSSL) req -new -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj "$(4)" \
		-keyout $(2) -out $(3)
endef

# call ssl_dhparam,OUTPUT_FILE
define ssl_dhparam
	@$(call prompt-info,Generate SSL dhparam"
	@(OPENSSL) dhparam -out $(1) 4096
endef
