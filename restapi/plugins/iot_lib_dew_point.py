class iot_LibDewPoint:
    def __init__(self, celsius, humidity):
        self._celsius=celsius
        self._humidity=humidity
        pass


    def Calc ():
        a=0
        b=0

        if self._celsius >= 0:
            a = 7.5
            b = 237.3
        elif self._celsius < 0:
            a = 7.6
            b = 240.7

        # Sättigungsdampfdruck (hPa)
        sdd = 6.1078 * math.pow(10, (a * self._celsius) / (b + self._celsius))

        # Dampfdruck (hPa)
        dd = sdd * (self._humidity / 100)

        # v-Parameter
        v = math.log10(dd / 6.1078)

        # Taupunkttemperatur (°C)
        td = (b * v) / (a - v)

        # Runden 1 Nachkommastelle
        #td =  math.round(td * 10) / 10

        return td

#print(calcdewpoint(25.6, 47))
#return msg;
