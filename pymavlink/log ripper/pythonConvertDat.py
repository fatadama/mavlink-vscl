class dataStruct:
    def __init__(self,nam,linedata):
        self.data = []
        self.data.append([])
        self.len = 0#number of variables in a message of this type
        self.datalen = 0#number of messages of this type received
        self.msglbls = []
        self.name = nam
        self.len = len(linedata)/3 - 1
        for i in range(self.len):
            num = linedata[3*i+5]
            lbl = linedata[3*i+3]
            if num[-1] == ',' or num[-1] == '{' or num[-1] == '}' :
                num = num[0:-1]
            if i == 0:
                self.data[0] = [num]
                lbl = lbl[1:len(lbl)]
                self.msglbls.append(lbl)
            else:
                self.data[0].append(num)
                self.msglbls.append(lbl)
    def update(self,linedata):
        self.datalen += 1
        for i in range(self.len):
            num = linedata[3*i+5]
            if num[-1] == ',' or num[-1] == '{' or num[-1] == '}' :
                num = num[0:-1]
                if i == 0:
                    self.data.append([num])
                else:
                    self.data[self.datalen].append(num)

def msgIndex(name,dataStructList):
    for i in range(len(dataStructList)):
        if name == dataStructList[i].name:
            return i
    return -1

def main(fid):
    msg_ids = []
    msg_id_count = 0

    data = []
    msg_len = []

    with fid:
        for line in fid:
            #print line
            dta = line.split()
            # use line.split()
            # the first two are incorrect times
            # third is the message identifier
            msg_id = dta[2]
            if msg_id != 'STATUSTEXT':
                if (msg_id in msg_ids):
                    inds = msg_ids.index(msg_id)
                    data[inds].update(dta)
                else:
                    msg_ids.append(msg_id)
                    msg_len.append(0)
                    data.append(dataStruct(msg_id,dta))
                    msg_id_count += 1
    return data
            
FLAGON = True
# set to True to write out roll/pitch/yaw attitude history

fname = raw_input("File name of telemetry .dat file:")
# verify that file exists
try:
    fid = open(fname,'r+')
except IOError:
    try:
        fid = open(fname+'.dat','r+')
    except IOError:
        print "File not found"
        FLAGON = False
except IOError:
    print "File not found"
    FLAGON = False

if FLAGON:
    data = main(fid)
    # write out roll history
    fidout = open('rollOutput.txt','w')
    fidout.write('time(msec)\troll(rad)\tpitch(rad)\tyaw(rad)\n')
    indRoll = msgIndex('ATTITUDE',data)
    for i in range(data[indRoll].datalen):
        fidout.write(str(data[indRoll].data[i][0]))
        for j in range(3):
            fidout.write('\t' + str(data[indRoll].data[i][j+1]))
        fidout.write('\n')
    print "Wrote history to rollOutput.txt"
    fidout.close()
    fid.close()

