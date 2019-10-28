gentestdata:
	dub run dubproxy -- -m true -n allcodedlangpackages.json
	dub run dubproxy -- -i allcodedlangpackages.json -a true -f testpackages -o \
		testpackages -u true
