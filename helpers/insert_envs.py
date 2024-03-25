import os
import re
import sys
from pprint import pprint

def insert_envs(path: str, out_path: str) -> None:

    with open(path, "r+") as target_file:
        content = target_file.read()
    
    pattern = re.compile(r"\$\{([A-Za-z_0-9]+)\}")
    write = True
    for m in pattern.finditer(content):
        env_value = os.getenv(m.group(1))
        if env_value is None:
            print(f"Not found env value for {m.group(0)}")
            write = False
            continue

        content = content.replace(m.group(0), env_value, 1)
    
    if write:
        with open(out_path, "w") as dest_file:
            dest_file.write(content)

    
if __name__ == "__main__":
    src_file = sys.argv[1]
    dest_file = sys.argv[2]

    insert_envs(src_file, dest_file)
