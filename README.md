# Описание
Репозиторий предназначен для помощи в процессе установки необходимых пакетов и запуске рабочей ноды в кластере кубернетес

# Скрипт протестирован на:
| Программа виртуализации | Основная ОС | Образ гостевой ОС |
|-------------------------|-------------|-------------------|  
| VirtualBox(7.1.4) | Windows11 (23H2)| ubuntu-24.04.1-live-server-amd64 |

Тип сетевого подключения: сетевой мост

# Скрипт не тестирован на:
- baremetal (установка убунту на железо без использования виртуальных машин)
- ubuntu desktop 24.04

# Инструкция по установка
1) После того, как виртуальная машина установлена, успешно запушена и имеет выход в интернет (`ping google.com` дает ответ), скопировать себе репозиторий:
```
cd ~
git clone https://github.com/cldcdr42/VBox-k8s-cluster
cd ~/Vbox-k8s-cluster
```

2) Перейти в роль суперюзера, поменять тип файл и запустить его
```
sudo su
chmod +x install_script.sh
```

Сообщения с логами об установке будут расположены в той же репозитории в файле install_script.log

3) Открыть файл 

```
nano install_script.sh
```

4) В окне напечатать следующие данные (печатать в кавычках). Пример приведен ниже

если у вас 
IP VPN 192.168.0.0
login student42
password dqenw;

то конфиг раздел файла должен выглядить так:
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

7) После окончания работы команды выполните перезагрузку системы
```
sudo reboot
```

# Включить или выключить установленный впн

On:
```
sudo pon vpn_PPTP
```

Off:
```
sudo pon vpn_PPTP
```

# Проверка работы установленных пакетов

Проверка наличия соединения VPN:
1) выключить vpn
2) sudo apt install traceroute
3) traceroute 1.1.1.1 >> vpn_test.log
4) sudo pon vpn_PPTP
5) traceroute 1.1.1.1 >> vpn_test.log
6) nano test.log
7) Сравнить результаты. Программа показывает маршрут, который проходит запрос до сервера 1.1.1.1 (ДНС сервер гугла). Если пути отличаются, то впн соединение работает успешно 

Проверка установки CRI-O
1) apt list --installed | grep "crio"
2) найти в списке cri-o, cri-o-runc, cri-tools и их версии (1.25)

Проверка установки k8s
1) apt list --installed | grep "kube"
2) найти в списке kubelet, kubeadm, kubectl

# Траблшутинг
Так

# Источники гайдов
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
