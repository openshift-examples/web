
import hashlib

def sha256(x):
    return hashlib.sha256(x.encode('utf-8')).hexdigest()

def on_env(env, config, files, **kwargs):
    env.filters['sha256'] = sha256
    return env