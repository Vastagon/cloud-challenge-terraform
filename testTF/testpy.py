import azure.functions as func


def main(req: func.HttpRequest, inputDocument: func.DocumentList):
    return "Hello"
