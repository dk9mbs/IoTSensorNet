
def output(context, field_name, value, rec={}):
    if value==None or value==0:
        return "No"
    else:
        return "Yes"


def input(context, value):
    return value
