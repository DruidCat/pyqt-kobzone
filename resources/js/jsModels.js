.pragma library

function parseModels(jsonString) {
    try {
        let data = JSON.parse(jsonString);
        let models = ["(автовыбор модели)"];
        
        if (data.data && Array.isArray(data.data)) {
            data.data.forEach(function(item) {
                if (item.id) {
                    models.push(item.id);
                }
            });
        }
        
        return models;
    } catch (e) {
        console.error("Ошибка парсинга JSON:", e);
        return ["(автовыбор модели)"];
    }
}

function formatModelName(fullName) {
    // Убираем путь, оставляем только имя
    let parts = fullName.split("/");
    return parts[parts.length - 1];
}
