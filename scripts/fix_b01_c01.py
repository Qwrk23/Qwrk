"""
Surgical fix for B01 (Save) and C01 (Promote) workflow bugs.
Operates on parsed JSON — no manual escaping needed.
"""
import json
import sys

def fix_b01(wf):
    """B01: Move extension JSON.parse to immediately after req definition, in-place."""
    for node in wf['nodes']:
        if node['name'] == 'NQxb_Artifact_Save_v1__Normalize_Request':
            code = node['parameters']['jsCode']

            # Verify old fix exists
            if 'rawExtension' not in code:
                print('B01 ERROR: rawExtension variable not found — old fix missing?')
                return False

            # Part 1: Insert early in-place parse right after req definition
            marker = 'const req = body ?? raw;\n\nconst asObj'
            if marker not in code:
                print('B01 ERROR: insertion marker not found')
                return False

            early_parse = (
                'const req = body ?? raw;\n'
                '\n'
                '// B01 fix: recover stringified extension in-place (before any extension refs)\n'
                "if (typeof req.extension === 'string') {\n"
                '  try {\n'
                '    req.extension = JSON.parse(req.extension);\n'
                '  } catch (e) {\n'
                '    req.extension = null;\n'
                '  }\n'
                '}\n'
                '\n'
                'const asObj'
            )
            code = code.replace(marker, early_parse, 1)
            print('  B01 Part 1: Inserted early in-place parse after req definition')

            # Part 2: Remove old rawExtension-based fix block
            old_start = '// Belt-and-suspenders: recover stringified extension (B01 fix)\n'
            old_end = 'const extension_obj = asObj(rawExtension);'
            si = code.find(old_start)
            ei = code.find(old_end)
            if si == -1 or ei == -1:
                # Try alternate: maybe "immediately" variant exists
                old_start_alt = '// Belt-and-suspenders: recover stringified extension immediately (B01 fix)\n'
                si = code.find(old_start_alt)
                if si != -1:
                    old_start = old_start_alt
                else:
                    print('B01 ERROR: old fix block boundaries not found')
                    return False

            code = (
                code[:si]
                + 'const extension_obj = asObj(req.extension);'
                + code[ei + len(old_end):]
            )
            print('  B01 Part 2: Removed old rawExtension block, reverted to asObj(req.extension)')

            node['parameters']['jsCode'] = code
            return True

    print('B01 ERROR: Normalize_Request node not found')
    return False


def fix_c01(wf):
    """C01: Use $node reference to bypass lossy Merge combineByPosition."""
    for node in wf['nodes']:
        if node['name'] == 'NQxb_Artifact_Promote_v1__Enforce_Verified_State':
            code = node['parameters']['jsCode']

            old_guard = (
                '// Short-circuit: if Resolve_Transition already errored, pass through its error (C01 fix)\n'
                'if (input.ok === false && input._gw_route === "error" && input.error) {\n'
                '  return [{ json: input }];\n'
                '}'
            )

            new_guard = (
                '// Short-circuit: if Resolve_Transition already errored, pass through its error (C01 fix)\n'
                '// Read directly from Resolve_Transition — bypasses lossy Merge combineByPosition\n'
                'const resolveOutput = $node["NQxb_Artifact_Promote_v1__Resolve_Transition"]?.json ?? {};\n'
                'if (resolveOutput.ok === false && resolveOutput._gw_route === "error" && resolveOutput.error) {\n'
                '  return [{ json: resolveOutput }];\n'
                '}'
            )

            if old_guard in code:
                code = code.replace(old_guard, new_guard, 1)
                node['parameters']['jsCode'] = code
                print('  C01: Replaced $json guard with $node["Resolve_Transition"] reference')
                return True
            else:
                print('C01 ERROR: old guard not found in Enforce_Verified_State')
                if 'C01 fix' in code:
                    idx = code.find('C01 fix')
                    ctx = code[max(0, idx-10):idx+200]
                    print(f'  Context around "C01 fix": {repr(ctx[:120])}')
                return False

    print('C01 ERROR: Enforce_Verified_State node not found')
    return False


if __name__ == '__main__':
    save_path = sys.argv[1]
    promote_path = sys.argv[2]

    print(f'=== B01 Fix: {save_path} ===')
    with open(save_path, 'r', encoding='utf-8') as f:
        save_wf = json.load(f)
    b01_ok = fix_b01(save_wf)
    if b01_ok:
        out = json.dumps(save_wf, indent=2, ensure_ascii=False) + '\n'
        with open(save_path, 'wb') as f:
            f.write(out.encode('utf-8'))
        print(f'  Written: {save_path}')

    print(f'\n=== C01 Fix: {promote_path} ===')
    with open(promote_path, 'r', encoding='utf-8') as f:
        promote_wf = json.load(f)
    c01_ok = fix_c01(promote_wf)
    if c01_ok:
        out = json.dumps(promote_wf, indent=2, ensure_ascii=False) + '\n'
        with open(promote_path, 'wb') as f:
            f.write(out.encode('utf-8'))
        print(f'  Written: {promote_path}')

    print(f'\n=== Results: B01={"PASS" if b01_ok else "FAIL"}, C01={"PASS" if c01_ok else "FAIL"} ===')
