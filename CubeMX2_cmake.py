#!/usr/bin/env python3
import sys
import re
import os
import os.path
import xml.etree.ElementTree

# Return codes
C2M_ERR_SUCCESS = 0
C2M_ERR_INVALID_COMMANDLINE = -1
C2M_ERR_LOAD_TEMPLATE = -2
C2M_ERR_NO_PROJECT = -3
C2M_ERR_PROJECT_FILE = -4
C2M_ERR_IO = -5
C2M_ERR_NEED_UPDATE = -6

# Configuration

# STM32 MCU to compiler flags.
mcu_regex_to_cflags_dict = {
    'STM32(F|L)0': '-mthumb -mcpu=cortex-m0',
    'STM32(F|L)1': '-mthumb -mcpu=cortex-m3',
    'STM32(F|L)2': '-mthumb -mcpu=cortex-m3',
    'STM32(F|L)3': '-mthumb -mcpu=cortex-m4 \
-mfpu=fpv4-sp-d16 -mfloat-abi=hard',
    'STM32(F|L)4': '-mthumb -mcpu=cortex-m4 \
-mfpu=fpv4-sp-d16 -mfloat-abi=hard',
    'STM32(F|L)7': '-mthumb -mcpu=cortex-m7 \
-mfpu=fpv4-sp-d16 -mfloat-abi=hard',
}


def main():
    proj_folder_path = os.path.abspath(sys.argv[1])
    if not os.path.isdir(proj_folder_path):
        sys.stderr.write("STM32CubeMX \"Toolchain Folder Location\" \
not found: {}\n".format(proj_folder_path))
        sys.exit(C2M_ERR_INVALID_COMMANDLINE)

    proj_name = os.path.splitext(os.path.basename(proj_folder_path))[0]
    ac6_project_path = os.path.join(proj_folder_path, '.project')
    ac6_cproject_path = os.path.join(proj_folder_path, '.cproject')
    if not (os.path.isfile(ac6_project_path)
            and os.path.isfile(ac6_cproject_path)):
        sys.stderr.write("SW4STM32 project not found, \
use STM32CubeMX to generate a SW4STM32 project first\n")
        sys.exit(C2M_ERR_NO_PROJECT)
    # .cproject file
    try:
        tree = xml.etree.ElementTree.parse(ac6_cproject_path)
    except Exception as e:
        sys.stderr.write("Unable to parse SW4STM32 .cproject file: {}. \
Error: {}\n".format(ac6_cproject_path, str(e)))
        sys.exit(C2M_ERR_PROJECT_FILE)
    root = tree.getroot()

    # MCU
    mcu_node = root.find('.//toolChain/option[@superClass="\
fr.ac6.managedbuild.option.gnu.cross.mcu"][@name="Mcu"]')
    try:
        mcu_str = mcu_node.attrib.get('value')
    except Exception as e:
        sys.stderr.write("Unable to find target MCU node. \
Error: {}\n".format(str(e)))
        sys.exit(C2M_ERR_PROJECT_FILE)
    for mcu_regex_pattern, cflags in mcu_regex_to_cflags_dict.items():
        if re.match(mcu_regex_pattern, mcu_str):
            cflags_subst = cflags
            break
    else:
        sys.stderr.write("Unknown MCU: {}\n".format(mcu_str))
        sys.stderr.write("Please contact author for an \
update of this utility.\n")
        sys.stderr.exit(C2M_ERR_NEED_UPDATE)
    # AS symbols
    # as_defs_subst = 'AS_DEFS ='
    # C symbols
    c_defs_subst = ''
    c_def_node_list = root.findall('.//tool/option[@valueType="\
definedSymbols"]/listOptionValue')
    for c_def_node in c_def_node_list:
        c_def_str = c_def_node.attrib.get('value')
        if c_def_str:
            def2 = ""
            if '=' in c_def_str:
                def2 = "\"" + c_def_str.split('=')[1] + "\""
                c_defs_subst += ' -D' + c_def_str.split('=')[0] + '=' + def2
            else:
                c_defs_subst += ' -D' + c_def_str

    # Link script
    ld_script_node_list = root.find('.//tool/option[@superClass="\
fr.ac6.managedbuild.tool.gnu.cross.c.linker.script"]')
    try:
        ld_script_path = ld_script_node_list.attrib.get('value')
    except Exception as e:
        sys.stderr.write("Unable to find link script. Error: {}\n".
                         format(str(e)))
        sys.exit(C2M_ERR_PROJECT_FILE)
    ld_script_name = os.path.basename(ld_script_path)
    print(proj_name,    ';',
          cflags_subst, ';',
          c_defs_subst, ';',
          mcu_str,      ';',
          ld_script_name)
    sys.exit(C2M_ERR_SUCCESS)


def fix_path(p):
    return re.sub(r'^..(\\|/)..(\\|/)..(\\|/)', '',
                  p.replace('\\', os.path.sep))


if __name__ == '__main__':
    main()
