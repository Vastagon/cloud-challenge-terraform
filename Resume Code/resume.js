async function updateCounter() {
    const res = await fetch("https://vastagon-function-app.azurewebsites.net/api/HttpCountTrigger?code=Fue-BcjoiWZLF7uu7Ncn-71uJxmG2FQ6WBu2KaNYOTEvAzFuDsxFxw==", {
        method: "POST"
    })
    const data = await res.json()
    const count = data[0].count

    document.getElementById("visit-count").innerText = `Visit count: ${count}`
}

updateCounter()


