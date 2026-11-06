import re

def parse_hstore(hstore_str):
    if not hstore_str:
        return {}
    result = {}
    pattern = re.compile(r'"((?:[^"\\]|\\.)*)"=>"((?:[^"\\]|\\.)*)"')
    for m in pattern.finditer(hstore_str):
        k = m.group(1).replace(r'\"', '"').replace(r'\\', '\\')
        v = m.group(2).replace(r'\"', '"').replace(r'\\', '\\')
        result[k] = v
    return result

sample = '"building:levels"=>"12","height"=>"36.5","addr:street"=>"Netaji Subhash Chandra Bose Rd","name:mr"=>"मरीन ड्राईव्ह"'
parsed = parse_hstore(sample)
print("Parsed hstore:", parsed)
print("Levels:", parsed.get("building:levels"), "Height:", parsed.get("height"))

