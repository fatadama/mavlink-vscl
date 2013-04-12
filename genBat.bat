@echo off
echo Clearing the directory gen_out
rmdir gen_out /S /Q
mkdir gen_out
echo Generating C files
python pymavlink/generator/mavgen.py --output=gen_out/ --lang=C --wire-protocol=1.0 message_definitions/v1.0/vscl.xml message_definitions/v1.0/ardupilotmega.xml
echo Generating python files
python pymavlink/generator/mavgen.py --output=gen_out/mavlinkv10.py --lang=python --wire-protocol=1.0 message_definitions/v1.0/vscl.xml message_definitions/v1.0/ardupilotmega.xml