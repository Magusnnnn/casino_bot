import random
import json
import os
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes

# === НАСТРОЙКИ ===
TOKEN = "8590865104:AAHt8nixuy5ICw50gmSAZdueo8SYvdyaTW8"
DATA_FILE = "casino_data.json"
ADMIN_ID = 2202208283799824
ADMIN_USERNAME = "@magusnnn"

# Цены на валюту
DONATE_PRICES = {
    "1000": 50,
    "5000": 200,
    "10000": 350,
    "50000": 1500,
}

# Загрузка данных
def load_data():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    return {}

# Сохранение данных
def save_data(data):
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f)

# Получение баланса пользователя
def get_balance(user_id):
    data = load_data()
    if str(user_id) in data:
        return data[str(user_id)]['balance']
    else:
        data[str(user_id)] = {'balance': 1000, 'username': ''}
        save_data(data)
        return 1000

# Обновление баланса
def update_balance(user_id, amount, username=""):
    data = load_data()
    if str(user_id) in data:
        data[str(user_id)]['balance'] += amount
        if username:
            data[str(user_id)]['username'] = username
    else:
        data[str(user_id)] = {'balance': 1000 + amount, 'username': username}
    save_data(data)
    return data[str(user_id)]['balance']

# Топ богачей
def get_rich_top():
    data = load_data()
    if not data:
        return "Пока нет игроков!"
    
    top_users = sorted(data.items(), key=lambda x: x[1]['balance'], reverse=True)[:10]
    
    result = "🏆 ТОП БОГАЧЕЙ 🏆\n\n"
    for i, (user_id, user_data) in enumerate(top_users, 1):
        username = user_data.get('username', f'Игрок {user_id}')
        balance = user_data['balance']
        result += f"{i}. {username}: 💰 {balance:,}\n"
    
    return result

# Команда /start
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    user_id = user.id
    
    balance = get_balance(user_id)
    update_balance(user_id, 0, user.first_name)
    
    keyboard = [
        [InlineKeyboardButton("🎰 Играть в слоты (10💰)", callback_data="slots")],
        [InlineKeyboardButton("🎲 Кости (50💰)", callback_data="dice")],
        [InlineKeyboardButton("🔢 Угадай число (25💰)", callback_data="guess")],
        [InlineKeyboardButton("📈 Топ богачей", callback_data="top"),
         InlineKeyboardButton("💰 Мой баланс", callback_data="balance")],
        [InlineKeyboardButton("💳 Купить валюту", callback_data="donate"),
         InlineKeyboardButton("🎁 Ежедневный бонус", callback_data="daily")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        f"🎰 Добро пожаловать в Казино, {user.first_name}! 🎰\n\n"
        f"💰 Ваш баланс: {balance}\n"
        "Выберите игру:",
        reply_markup=reply_markup
    )

# Команда /play для групп
async def play_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    user_id = user.id
    
    balance = get_balance(user_id)
    update_balance(user_id, 0, user.first_name)
    
    keyboard = [
        [InlineKeyboardButton("🎰 Слоты (10💰)", callback_data="slots")],
        [InlineKeyboardButton("🎲 Кости (50💰)", callback_data="dice")],
        [InlineKeyboardButton("💰 Баланс", callback_data="balance")],
        [InlineKeyboardButton("📈 Топ", callback_data="top")],
        [InlineKeyboardButton("💳 Купить валюту", callback_data="donate")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        f"🎰 Казино-бот 🎰\n"
        f"Игрок: {user.first_name}\n"
        f"Баланс: {balance}💰\n\n"
        f"Выберите игру:",
        reply_markup=reply_markup
    )

# Меню доната
async def donate_menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user = query.from_user
    
    keyboard = [
        [InlineKeyboardButton("1000💰 - 50₽", callback_data="buy_1000")],
        [InlineKeyboardButton("5000💰 - 200₽", callback_data="buy_5000")],
        [InlineKeyboardButton("10000💰 - 350₽", callback_data="buy_10000")],
        [InlineKeyboardButton("50000💰 - 1500₽", callback_data="buy_50000")],
        [InlineKeyboardButton("🔙 Назад", callback_data="back")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        f"💳 ПОКУПКА ВАЛЮТЫ 💳\n\n"
        "Выберите пакет валюты:\n\n"
        "• 1000💰 - 50₽\n"
        "• 5000💰 - 200₽\n"
        "• 10000💰 - 350₽\n"
        "• 50000💰 - 1500₽\n\n"
        "После оплаты отправьте скриншот администратору.",
        reply_markup=reply_markup
    )

# Обработка выбора пакета доната
async def handle_donate_choice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user = query.from_user
    
    packages = {
        "buy_1000": {"coins": 1000, "price": 50},
        "buy_5000": {"coins": 5000, "price": 200},
        "buy_10000": {"coins": 10000, "price": 350},
        "buy_50000": {"coins": 50000, "price": 1500}
    }
    
    choice = query.data
    if choice in packages:
        package = packages[choice]
        
        await query.edit_message_text(
            f"💳 ВЫБРАН ПАКЕТ: {package['coins']}💰\n\n"
            f"💵 Сумма к оплате: {package['price']}₽\n\n"
            f"💳 Реквизиты для оплаты:\n"
            f"• Карта: {ADMIN_ID}\n"
            f"• СБП: по номеру карты\n\n"
            f"💬 После оплаты отправьте скриншот администратору {ADMIN_USERNAME}\n"
            "После проверки валюта будет зачислена на ваш счет!",
            reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 Назад", callback_data="donate")]])
        )

# Команда для администратора - зачисление валюты
async def add_coins(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    
    if user_id != ADMIN_ID:
        await update.message.reply_text("❌ Эта команда только для администратора!")
        return
    
    if len(context.args) != 2:
        await update.message.reply_text("Использование: /addcoins USER_ID AMOUNT")
        return
    
    try:
        target_user_id = int(context.args[0])
        amount = int(context.args[1])
        
        new_balance = update_balance(target_user_id, amount)
        
        await update.message.reply_text(
            f"✅ Пользователю {target_user_id} зачислено {amount}💰\n"
            f"Новый баланс: {new_balance}💰"
        )
        
    except ValueError:
        await update.message.reply_text("❌ Ошибка: USER_ID и AMOUNT должны быть числами")

# Ежедневный бонус
async def daily_bonus(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    
    bonus = random.randint(50, 200)
    new_balance = update_balance(user_id, bonus)
    
    await query.edit_message_text(
        f"🎁 ЕЖЕДНЕВНЫЙ БОНУС 🎁\n\n"
        f"🎉 Вы получили: {bonus}💰\n"
        f"💰 Новый баланс: {new_balance}💰"
    )
    await show_game_buttons(query, new_balance)

# Игра "Угадай число"
async def guess_number(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    balance = get_balance(user_id)
    
    if balance < 25:
        await query.answer("❌ Недостаточно средств! Нужно 25💰", show_alert=True)
        return
    
    secret_number = random.randint(1, 10)
    context.user_data['secret_number'] = secret_number
    
    keyboard = [[InlineKeyboardButton(str(i), callback_data=f"guess_{i}") for i in range(1, 6)],
                [InlineKeyboardButton(str(i), callback_data=f"guess_{i}") for i in range(6, 11)],
                [InlineKeyboardButton("🔙 Назад", callback_data="back")]]
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        "🔢 УГАДАЙ ЧИСЛО (1-10)\n\n"
        "Ставка: 25💰\n"
        "Выигрыш: 75💰\n\n"
        "Выберите число:",
        reply_markup=reply_markup
    )

# Проверка угаданного числа
async def check_guess(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    
    if 'secret_number' not in context.user_data:
        await query.answer("❌ Ошибка игры! Начните заново.", show_alert=True)
        return
    
    guessed_number = int(query.data.split('_')[1])
    secret_number = context.user_data['secret_number']
    
    update_balance(user_id, -25)
    
    if guessed_number == secret_number:
        win_amount = 75
        result_text = f"🎉 Поздравляем! Вы угадали число {secret_number}!"
        new_balance = update_balance(user_id, win_amount)
    else:
        win_amount = 0
        result_text = f"😞 Не угадали! Загаданное число было {secret_number}."
        new_balance = get_balance(user_id)
    
    message = f"🔢 УГАДАЙ ЧИСЛО 🔢\n\n"
    message += f"Ваш выбор: {guessed_number}\n"
    message += f"Загаданное число: {secret_number}\n\n"
    message += f"{result_text}\n"
    
    if win_amount > 0:
        message += f"🏆 Выигрыш: {win_amount}💰\n"
    
    message += f"💰 Новый баланс: {new_balance}💰"
    
    await query.edit_message_text(message)
    await show_game_buttons(query, new_balance)

# Показ кнопок игр
async def show_game_buttons(query, balance):
    keyboard = [
        [InlineKeyboardButton("🎰 Играть в слоты (10💰)", callback_data="slots")],
        [InlineKeyboardButton("🎲 Кости (50💰)", callback_data="dice")],
        [InlineKeyboardButton("🔢 Угадай число (25💰)", callback_data="guess")],
        [InlineKeyboardButton("📈 Топ богачей", callback_data="top"),
         InlineKeyboardButton("💰 Мой баланс", callback_data="balance")],
        [InlineKeyboardButton("💳 Купить валюту", callback_data="donate"),
         InlineKeyboardButton("🎁 Ежедневный бонус", callback_data="daily")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        f"💰 Ваш баланс: {balance}\nВыберите игру:",
        reply_markup=reply_markup
    )

# Игра в слоты
async def play_slots(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    balance = get_balance(user_id)
    
    if balance < 10:
        await query.answer("❌ Недостаточно средств! Нужно 10💰", show_alert=True)
        return
    
    symbols = ["🍒", "🍋", "🍊", "🍇", "🔔", "💎", "7️⃣"]
    result = [random.choice(symbols) for _ in range(3)]
    slot_display = " | ".join(result)
    
    win = 0
    if result[0] == result[1] == result[2]:
        if result[0] == "7️⃣":
            win = 500
        elif result[0] == "💎":
            win = 200
        elif result[0] == "🔔":
            win = 100
        else:
            win = 50
    elif result[0] == result[1] or result[1] == result[2]:
        win = 15
    
    new_balance = update_balance(user_id, win - 10)
    
    message = f"🎰 СЛОТ-МАШИНА 🎰\n\n"
    message += f"Результат: {slot_display}\n\n"
    
    if win > 0:
        if win == 500:
            message += "🎉 ДЖЕКПОТ! 7️⃣7️⃣7️⃣ 🎉\n"
        message += f"🏆 Вы выиграли: {win}💰\n"
    else:
        message += "😞 Повезет в следующий раз!\n"
    
    message += f"💰 Новый баланс: {new_balance}💰"
    
    await query.edit_message_text(message)
    await show_game_buttons(query, new_balance)

# Игра в кости
async def play_dice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    user_id = query.from_user.id
    balance = get_balance(user_id)
    
    if balance < 50:
        await query.answer("❌ Недостаточно средств! Нужно 50💰", show_alert=True)
        return
    
    bot_dice = random.randint(1, 6)
    player_dice = random.randint(1, 6)
    
    if player_dice > bot_dice:
        win_amount = 80
        result_text = "🎉 Вы выиграли!"
    elif player_dice < bot_dice:
        win_amount = -50
        result_text = "😞 Вы проиграли!"
    else:
        win_amount = 0
        result_text = "🤝 Ничья!"
    
    new_balance = update_balance(user_id, win_amount)
    
    message = f"🎲 ИГРА В КОСТИ 🎲\n\n"
    message += f"Ваш кубик: {player_dice}\n"
    message += f"Кубик казино: {bot_dice}\n\n"
    message += f"{result_text}\n"
    
    if win_amount > 0:
        message += f"🏆 Выигрыш: {win_amount}💰\n"
    
    message += f"💰 Новый баланс: {new_balance}💰"
    
    await query.edit_message_text(message)
    await show_game_buttons(query, new_balance)

# Обработка callback-ов
async def button_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    data = query.data
    
    if data == "slots":
        await play_slots(update, context)
    elif data == "dice":
        await play_dice(update, context)
    elif data == "guess":
        await guess_number(update, context)
    elif data == "donate":
        await donate_menu(update, context)
    elif data.startswith("buy_"):
        await handle_donate_choice(update, context)
    elif data.startswith("guess_"):
        await check_guess(update, context)
    elif data == "daily":
        await daily_bonus(update, context)
    elif data == "balance":
        user_id = query.from_user.id
        balance = get_balance(user_id)
        await query.answer(f"💰 Ваш баланс: {balance}💰", show_alert=True)
    elif data == "top":
        top_list = get_rich_top()
        await query.edit_message_text(top_list)
        await show_game_buttons(query, get_balance(query.from_user.id))
    elif data == "back":
        await show_game_buttons(query, get_balance(query.from_user.id))

# Основная функция
def main():
    application = Application.builder().token(TOKEN).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("play", play_cmd))
    application.add_handler(CommandHandler("addcoins", add_coins))
    application.add_handler(CallbackQueryHandler(button_handler))
    
    print("🎰 Казино-бот запущен!")
    application.run_polling()

if __name__ == "__main__":
    main()
