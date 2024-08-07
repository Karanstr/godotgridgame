extends Node

static var maxInt = 9223372036854775807

func bitCount(number:int):
	var bits:int = 0
	while number != 0:
		number >>=1;
		bits+=1
	return bits
