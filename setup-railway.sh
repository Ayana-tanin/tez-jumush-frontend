#!/bin/bash

# ================================
# Скрипт быстрой настройки Tez Jumush для Railway
# ================================

echo "🚀 Настройка проекта Tez Jumush для Railway..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверяем наличие Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js не установлен. Установите Node.js 18+ и повторите попытку.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js найден: $(node --version)${NC}"

# Проверяем наличие npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm не найден. Установите npm и повторите попытку.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm найден: $(npm --version)${NC}"

# Создаем .env файл для бэкенда
echo -e "${BLUE}📝 Создаю файл конфигурации для бэкенда...${NC}"

cat > backend/.env << EOF
# MySQL подключение Railway
MYSQL_URL=mysql://USER:PASSWORD@HOST:PORT/railway

# JWT секретный ключ
JWT_SECRET=CHANGE_ME_random_long_secret

# Порт сервера
PORT=4000

# Режим разработки
NODE_ENV=development

# URL фронтенда для CORS
FRONTEND_URL=http://localhost:3000
EOF

echo -e "${GREEN}✅ Файл backend/.env создан${NC}"

# Создаем .env файл для фронтенда
echo -e "${BLUE}📝 Создаю файл конфигурации для фронтенда...${NC}"

cat > .env.local << EOF
# Google Authentication (замените на ваш Client ID)
VITE_GOOGLE_CLIENT_ID=your_google_client_id_here

# API URL (для разработки)
VITE_API_URL=http://localhost:4000

# Режим разработки
VITE_APP_ENV=development
EOF

echo -e "${GREEN}✅ Файл .env.local создан${NC}"

# Устанавливаем зависимости бэкенда
echo -e "${BLUE}📦 Устанавливаю зависимости бэкенда...${NC}"
cd backend
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка установки зависимостей бэкенда${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Зависимости бэкенда установлены${NC}"

# Компилируем TypeScript
echo -e "${BLUE}🔨 Компилирую TypeScript...${NC}"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка компиляции TypeScript${NC}"
    exit 1
fi
echo -e "${GREEN}✅ TypeScript скомпилирован${NC}"

# Выполняем миграции
echo -e "${BLUE}🗄️ Выполняю миграции базы данных...${NC}"
npm run migrate
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️ Возможная ошибка миграций. Проверьте подключение к БД${NC}"
else
    echo -e "${GREEN}✅ Миграции выполнены успешно${NC}"
fi

# Возвращаемся в корневую директорию
cd ..

# Устанавливаем зависимости фронтенда
echo -e "${BLUE}📦 Устанавливаю зависимости фронтенда...${NC}"
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка установки зависимостей фронтенда${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Зависимости фронтенда установлены${NC}"

# Создаем скрипт для запуска разработки
cat > start-dev.sh << 'EOF'
#!/bin/bash
echo "🚀 Запуск Tez Jumush в режиме разработки..."

# Запускаем бэкенд в фоне
echo "📡 Запускаю бэкенд на порту 4000..."
cd backend && npm run dev &
BACKEND_PID=$!

# Ждем запуска бэкенда
sleep 3

# Запускаем фронтенд
echo "🌐 Запускаю фронтенд на порту 3000..."
cd .. && npm run dev &
FRONTEND_PID=$!

# Функция для остановки процессов
cleanup() {
    echo "🛑 Останавливаю процессы..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit 0
}

# Обработчик сигналов
trap cleanup SIGINT SIGTERM

echo "✅ Приложение запущено!"
echo "🌐 Фронтенд: http://localhost:3000"
echo "📡 API: http://localhost:4000/api/health"
echo "⏹️ Нажмите Ctrl+C для остановки"

# Ждем завершения
wait
EOF

chmod +x start-dev.sh

# Создаем скрипт для деплоя
cat > deploy-railway.sh << 'EOF'
#!/bin/bash
echo "🚀 Подготовка к деплою на Railway..."

# Компилируем бэкенд
echo "🔨 Компилирую бэкенд..."
cd backend && npm run build

if [ $? -eq 0 ]; then
    echo "✅ Бэкенд готов к деплою"
else
    echo "❌ Ошибка компиляции бэкенда"
    exit 1
fi

cd ..

# Компилируем фронтенд
echo "🔨 Компилирую фронтенд..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Фронтенд готов к деплою"
else
    echo "❌ Ошибка компиляции фронтенда"
    exit 1
fi

echo "🎉 Проект готов к деплою!"
echo "📋 Следующие шаги:"
echo "1. Загрузите код на GitHub"
echo "2. Создайте проект на Railway"
echo "3. Настройте переменные окружения"
echo "4. Деплойте бэкенд на Railway"
echo "5. Деплойте фронтенд на Vercel/Netlify"
EOF

chmod +x deploy-railway.sh

# Финальное сообщение
echo -e "${GREEN}"
echo "🎉 Настройка завершена успешно!"
echo ""
echo "📋 Что дальше:"
echo "1. Настройте Google OAuth:"
echo "   - Перейдите в Google Cloud Console"
echo "   - Создайте OAuth Client ID"
echo "   - Замените 'your_google_client_id_here' в .env.local"
echo ""
echo "2. Запустите проект в режиме разработки:"
echo "   ./start-dev.sh"
echo ""
echo "3. Для деплоя на Railway:"
echo "   ./deploy-railway.sh"
echo ""
echo "🌐 URL после запуска:"
echo "   Фронтенд: http://localhost:3000"
echo "   API: http://localhost:4000/api/health"
echo ""
echo "📚 Подробная инструкция: RAILWAY_DEPLOYMENT.md"
echo -e "${NC}"