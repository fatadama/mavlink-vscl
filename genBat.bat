@echo off
echo Clearing the directory gen_out
rmdir gen_out /S /Q
mkdir gen_out
echo Generating C files
python pymavlink/generator/mavgen.py --output=gen_out/ --lang=C --wire-protocol=1.0 message_definitions/v1.0/ardupilotmega.xml
echo Generating python files
python pymavlink/generator/mavgen.py --output=gen_out/mavlinkv10.py --lang=python --wire-protocol=1.0 message_definitions/v1.0/ardupilotmega.xml
echo copying C files to Arduino libraries directory
rmdir ..\libraries\GCS_MAVLink\include\mavlink\v1.0\ardupilotmega \S \Q
mkdir ..\libraries\GCS_MAVLink\include\mavlink\v1.0\ardupilotmega
copy gen_out\ardupilotmega ..\libraries\GCS_MAVLink\include\mavlink\v1.0\ardupilotmega
echo copying mavlinkv10.py to the pymavlink folder
del pymavlink\mavlinkv10.py
copy gen_out\mavlinkv10.py pymavlink\mavlinkv10.py
echo complete
pause