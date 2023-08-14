async function updateCounter() {
    const res = await fetch("https://vastagonresumecountapi.azurewebsites.net/api/UpdateVisitCount?code=vkWbdknVU5eE-hHjIGv3-_SYny77exqri0dlogICMPJFAzFuXX7YCg==", {
        method: "POST"
    })
    const data = await res.json()
    const count = data[0].count

    document.getElementById("visit-count").innerText = `Visit count: ${count}`
}

updateCounter()


function testThing() {
    console.log(`import azure.functions as func \n\n\ndef main(req: func.HttpRequest, inputDocument: func.DocumentList):\n    if inputDocument:\n        totalCount = inputDocument[0]\n        updatedCount = totalCount['count']\n        updatedCount = updatedCount + 1\n\n        totalCount['count'] = updatedCount\n        return totalCount\n    else:\n        return func.Document.from_dict({"id": "count", "count": 0})\n`)

}

testThing()