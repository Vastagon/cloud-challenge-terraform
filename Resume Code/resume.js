async function updateCounter() {
    const res = await fetch("https://vastagon-function-app.azurewebsites.net/api/HttpCountTrigger?code=0t2madQxQ5AqJCb0jdJOayBYUd6-73ED4AvqKZJlYz1xAzFuyAkSgQ==", {
        method: "POST"
    })
    const data = await res.json()
    const count = data[0].count

    document.getElementById("visit-count").innerText = `Visit count: ${count}`
}

updateCounter()


