
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем Инструменты;

// Интерфейсная процедура, выполняет регистрацию команды и настройку парсера командной строки
//   
// Параметры:
//   ИмяКоманды 	- Строка										- Имя регистрируемой команды
//   Парсер 		- ПарсерАргументовКоманднойСтроки (cmdline)		- Парсер командной строки
//
Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Выполняет компрессию страниц таблиц и индексов в базе MS SQL");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-params",
		"Файлы JSON содержащие значения параметров,
		|могут быть указаны несколько файлов разделенные "";""
		|(параметры командной строки имеют более высокий приоритет)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-sql-srvr",
		"Адрес сервера MS SQL");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-sql-user",
		"Пользователь сервера");
		
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-sql-pwd",
		"Пароль пользователя сервера");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-sql-db",
		"Имя базы для восстановления");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, 
		"-shrink-db",
		"Сжать базу после выполнения компрессии");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры // ЗарегистрироватьКоманду()

// Интерфейсная процедура, выполняет текущую команду
//   
// Параметры:
//   ПараметрыКоманды 	- Соответствие						- Соответствие параметров команды и их значений
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	ЗапускПриложений.ПрочитатьПараметрыКомандыИзФайла(ПараметрыКоманды["-params"], ПараметрыКоманды);
	
	Сервер					= ПараметрыКоманды["-sql-srvr"];
	База					= ПараметрыКоманды["-sql-db"];
	Пользователь			= ПараметрыКоманды["-sql-user"];
	ПарольПользователя		= ПараметрыКоманды["-sql-pwd"];
	СжатьБазу				= ПараметрыКоманды["-shrink-db"];

	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();

	Если ПустаяСтрока(Сервер) Тогда
		Лог.Ошибка("Не указан сервер MS SQL");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(База) Тогда
		Лог.Ошибка("Не указана база для выполнения компрессии");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Инструменты = Новый ИнструментыСУБД;

	Попытка
		Инструменты.Инициализировать(Сервер, Пользователь, ПарольПользователя);
	Исключение
		Лог.Ошибка("Ошибка при инициализации инструментов СУБД: " + ОписаниеОшибки());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;

	Если НЕ ВключитьКомпрессию(База) Тогда
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецЕсли;
	
	Если СжатьБазу Тогда
		СжатьБазу(База);
	КонецЕсли;
	
	Возврат ВозможныйРезультат.Успех;

КонецФункции // ВыполнитьКоманду()

// Включает компрессию данных базы на уровне страниц
//   
// Параметры:
//   База 				- Строка				- имя базы
//
// Возвращаемое значение:
//	Булево - Истина - команда выполнена успешно; Ложь - в противном случае
//
Функция ВключитьКомпрессию(База) Экспорт

	Лог.Информация("Начало компрессии страниц базы ""%1""", База);
		
	Попытка
		Результат = Инструменты.ВключитьКомпрессиюСтраниц(База);

		Если НЕ Результат Тогда
			Лог.Ошибка("Ошибка включения компрессии страниц в базе ""%1""", База);
			Возврат Ложь;
		КонецЕсли;

		Лог.Информация("Включена компрессия страниц в базе ""%1""", База);
	Исключение
		Лог.Ошибка("Ошибка включения компрессии страниц в базе ""%1"": ""%2""", База, ОписаниеОшибки());
		Возврат Ложь;
	КонецПопытки;

	Возврат Истина;

КонецФункции // ВключитьКомпрессию()

// Выполняет сжатие базы (shrink)
//   
// Параметры:
//   База 				- Строка				- имя базы
//
// Возвращаемое значение:
//	Булево - Истина - команда выполнена успешно; Ложь - в противном случае
//
Функция СжатьБазу(База) Экспорт

	Лог.Информация("Начало сжатия (shrink) базы ""%1""", База);
		
	Попытка
		Результат = Инструменты.СжатьБазу(База);

		Если НЕ Результат Тогда
			Лог.Ошибка("Ошибка сжатия базы ""%1""", База);
			Возврат Ложь;
		КонецЕсли;

		Лог.Информация("Выполнено сжатие базы ""%1""", База);
	Исключение
		Лог.Ошибка("Ошибка сжатия базы ""%1"": ""%2""", База, ОписаниеОшибки());
		Возврат Ложь;
	КонецПопытки;

	Возврат Истина;

КонецФункции // СжатьБазу()

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");