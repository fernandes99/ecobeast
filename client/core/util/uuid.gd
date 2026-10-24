class_name Uuid
extends RefCounted
## Identificadores únicos (UUID versão 4, aleatório).


## Ex.: "3f2b8c1e-9a4d-4f6b-8e2a-1c5d7e9f0a3b".
static func v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0F) | 0x40  # versão 4
	bytes[8] = (bytes[8] & 0x3F) | 0x80  # variante RFC 4122
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
			hex.substr(16, 4), hex.substr(20, 12)]
