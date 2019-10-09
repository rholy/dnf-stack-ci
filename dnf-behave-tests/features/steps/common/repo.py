import os

from . import sha256_checksum


def generate_metalink(destdir, url):
    metalink = """<?xml version="1.0" encoding="utf-8"?>
<metalink version="3.0" xmlns="http://www.metalinker.org/" xmlns:mm0="http://fedorahosted.org/mirrormanager">
  <files>
    <file name="repomd.xml">
      <mm0:timestamp>1550000000</mm0:timestamp>
      <size>{size}</size>
      <verification>
        <hash type="sha256">{csum}</hash>
      </verification>
      <resources>
        <url protocol="{schema}" type="{schema}">{url}/repodata/repomd.xml</url>
      </resources>
    </file>
  </files>
</metalink>
"""
    schema = url.split(':')[0]
    with open(os.path.join(destdir, 'repodata', 'repomd.xml')) as f:
        repomd = f.read()
    with open(os.path.join(destdir, 'metalink.xml'), 'w') as f:
        data = metalink.format(
            size=len(repomd),
            csum=sha256_checksum(repomd.encode('utf-8')),
            schema=schema,
            url=url,
        )
        f.write(data + '\n')
