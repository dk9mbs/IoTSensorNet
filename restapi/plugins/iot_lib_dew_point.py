import math

class iot_LibDewPoint:
    def __init__(self, celsius, humidity):
        self._celsius=celsius
        self._relative_humidity=humidity
        self._dew_point=0.0
        self._absolute_humidity=0.0
        pass

    def get_dew_point(self):
        return self._dew_point

    def calc (self):
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
        dd = sdd * (self._relative_humidity / 100)

        # v-Parameter
        v = math.log10(dd / 6.1078)

        # Taupunkttemperatur (°C)
        td = (b * v) / (a - v)

        # Runden 1 Nachkommastelle
        td = round(td,2)
        #td =  math.round(td * 100) / 100

        self._dew_point=td
        #return td

