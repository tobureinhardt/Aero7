#!/usr/bin/env python3
# Minimal structural check for Lua files when no Lua interpreter is available: strips comments/strings and
# verifies function/if/for/while/do/repeat blocks are balanced. NOT a full parser - it cannot catch type or name errors.
import re, sys
def strip(src):
    out=[]; i=0; n=len(src)
    while i<n:
        c=src[i]
        if src.startswith('--',i):
            m=re.match(r'--\[(=*)\[',src[i:])
            if m:
                close=']'+m.group(1)+']'; j=src.find(close,i); i=n if j<0 else j+len(close)
            else:
                j=src.find('\n',i); i=n if j<0 else j
            continue
        m=re.match(r'\[(=*)\[',src[i:])
        if m:
            close=']'+m.group(1)+']'; j=src.find(close,i); i=n if j<0 else j+len(close); out.append(' S '); continue
        if c in '"\'':
            q=c; i+=1
            while i<n and src[i]!=q:
                if src[i]=='\\': i+=1
                i+=1
            i+=1; out.append(' S '); continue
        out.append(c); i+=1
    return ''.join(out)
def check(path):
    s=strip(open(path,encoding='utf-8').read()); stack=[]; line=1
    toks=re.finditer(r'\n|[A-Za-z_][A-Za-z_0-9]*',s); pending_do=0
    for m in toks:
        t=m.group(0)
        if t=='\n': line+=1; continue
        if t in('function','if','repeat'): stack.append((t,line))
        elif t in('for','while'): stack.append((t,line)); pending_do+=1
        elif t=='do':
            if pending_do>0: pending_do-=1
            else: stack.append((t,line))
        elif t=='end':
            if not stack or stack[-1][0]=='repeat': return f"{path}: unexpected 'end' at line {line}"
            stack.pop()
        elif t=='until':
            if not stack or stack[-1][0]!='repeat': return f"{path}: unexpected 'until' at line {line}"
            stack.pop()
    return f"{path}: OK (balanced)" if not stack else f"{path}: UNCLOSED {stack[-3:]}"
for p in sys.argv[1:]: print(check(p))
