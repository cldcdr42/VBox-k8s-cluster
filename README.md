# Описание
Репозиторий предназначен для помощи в процессе установки необходимых пакетов и запуске рабочей ноды в кластере кубернетес

# Цели
(Ok - сделано, WiP - работа в процессе/в планах)
1) (Ok) Добавить скрипт установки PPTP, CRI-O, k8s
2) (WiP) Добавить скрипт подключения к ноде
3) (WiP) Протестировать работу скриптов на серверной убунту 24.04
4) (Ok) Протестировать работу скриптов на десктоп убунту 24.04
5) (WiP) Написать инструкции с процессом установки, подключения к кластеру и отладкой основных проблем

## Содержание

1. [Работоспособность](#Работоспособность)
2. [Инструкция по установке](#Инструкция-по-установке)
3. [Работа с VPN](#Работа-с-VPN)
4. [Проверка установленных пакетов](#Проверка-установленных-пакетов)
5. [Траблшутинг](#Траблшутинг)
6. [Мой опыт установки](#Мой-опыт-установки)
7. [Источники гайдов](#Источники-гайдов)

## Работоспособность
Скрипт протестирован на

| Программа виртуализации | Основная ОС | Образ гостевой ОС |
|-------------------------|-------------|-------------------|  
| VirtualBox(7.1.4) | Windows11 (23H2)| ubuntu-24.04.1-live-server-amd64 |

Тип сетевого подключения: сетевой мост

Скрипт не протестирован на:
- ubuntu desktop 24.04
- baremetal

## Инструкция по установке
1) После того, как виртуальная машина установлена, успешно запушена и имеет выход в интернет (`ping google.com` дает ответ), скопировать себе репозиторий:
```
cd ~
git clone https://github.com/cldcdr42/VBox-k8s-cluster
cd ~/Vbox-k8s-cluster
```

2) Перейти в роль суперюзера, поменять тип файла и запустить его
```
sudo su
chmod +x install_script.sh
```
Сообщения с логами об установке будут расположены в той же репозитории в файле install_script.log

3) Открыть файл 
```
nano install_script.sh
```

4) В окне конфига (самое начало файла) напечатать следующие данные (пример приведен ниже):

если у вас следующие данные для подключения (данные предоставляются лицом, настраивающим впн)  
> VPN IP: 192.168.0.0  
> VPN логин: student42  
> VPN пароль: dqenw;  

То конфиг раздел файла должен выглядить так:
```
vpn_address="192.168.0.0"
name="student42"

# MAKE SURE TO PUT BACKSLASH \ BEFORE $ SIGNS IN PASSWORDS
# BAD:   password="124$23"
# GOOD:  password="124\$23"
password="dqenw;"
filename="vpn_PPTP"

OS="xUbuntu_22.04"
VERSION="1.25"
``` 
Обратите внимание, что при наличии символов $ следует ставить обратный слеш символ (\) перед ними. Пример приведе в файле 

5) сохраните файл
- (CTRL+X)
- y
- Enter

6) Запустите скрипт 
```
./install_script.sh > install_script.log 2>&1
```
Если в процессе выполнения поступип запрос с вводом [y/n], введите y и нажмите Enter

7) После окончания работы команды выполните перезагрузку системы
```
sudo reboot
```

## Работа с VPN

On:
```
sudo pon vpn_PPTP
```

Off:
```
sudo pon vpn_PPTP
```

## Проверка установленных пакетов

Проверка наличия соединения VPN:
1) выключить vpn
2) `sudo apt install traceroute`
3) `traceroute 1.1.1.1 >> vpn_test.log`
4) `sudo pon vpn_PPTP`
5) `traceroute 1.1.1.1 >> vpn_test.log`
6) `nano test.log`
7) Сравнить результаты. Программа показывает маршрут, который проходит запрос до сервера 1.1.1.1 (ДНС сервер гугла). Если пути отличаются, то впн соединение работает успешно 

Проверка установки CRI-O
1) `apt list --installed | grep "crio"`
2) найти в списке cri-o, cri-o-runc, cri-tools и их версии (1.25)

Проверка установки k8s
1) `apt list --installed | grep "kube"`
2) найти в списке kubelet, kubeadm, kubectl

Проверка SWAP
1) `swapon -s`
2) если команда выполнена и отсутвует вывод, то Swap выключен

Проверка статуса CRI-O
1) `systemctl status crio`
2) Статус должен быть Active (running)
3) Если статус не Active (running), запустите снова: `systemctl start crio && systemctl enable crio`

## Траблшутинг
| Проблема | Решение |
| -------- | ------- |
| **Нет интернета на виртуальной машине** | 1) Проверьте, что интернет есть на основной машине |
| | 2) Проверьте, что в настройках сети VirtualBox для ВМ выбран сетевой мост с корректным адаптером |
| | 3) Проверьте наличие включенных VPN на основной машине, выключите их |
| | 4) Некоторые копроративные/университетские сети могут блокировать трафик. Попробуйте использовать мобильный интернет|
| **Скрипт не сработал польностью, установил не все** | 1) Попробуйте запустить его снова|
|| 2) Просмотрите файл логов с описанием возникших проблем |
|||

## [Мой опыт установки](https://github.com/cldcdr42/VBox-k8s-cluster/wiki)

## Источники гайдов
основной гайд по установке CRI-O и k8s
https://timeweb.cloud/tutorials/kubernetes/kak-ustanovit-i-nastroit-kubernetes-ubuntu

установка CRI-O
https://scriptcrunch.com/install-cri-o-ubuntu/

установка kubernetes
https://v1-29.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

включение буфера обмена в гостевой ос
https://www.techrepublic.com/article/how-to-enable-copy-and-paste-in-virtualbox/

PPTP vpn клиент на linux (без десктопа)
https://www.russianproxy.ru/pptp-client-setup-debian-ubuntu  
https://www.networkinghowtos.com/howto/connect-to-a-pptp-vpn-server-from-ubuntu-linux/
