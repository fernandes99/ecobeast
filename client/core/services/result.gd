class_name Result
extends RefCounted
## Resposta de um serviço (.specs/foundation/architecture.md, "Serviços e Result").
## A tela confere ok; se falso, mostra error e mantém o jogador onde está.

var ok: bool = false
var data: Variant = null
## Mensagem em pt-BR, pronta para a tela. Vazia quando ok.
var error: String = ""


static func success(value: Variant = null) -> Result:
	var result := Result.new()
	result.ok = true
	result.data = value
	return result


static func failure(message: String) -> Result:
	var result := Result.new()
	result.error = message
	return result
