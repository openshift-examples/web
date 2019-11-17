# Commands inside a POD

## Get IP Addresses without ip or ifconfig?

{% tabs %}
{% tab title="Command" %}
```text
cat /proc/net/fib_trie
```
{% endtab %}

{% tab title="Sample outpout" %}
```
$ cat /proc/net/fib_trie
Main:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
Local:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
```
{% endtab %}
{% endtabs %}

{% tabs %}
{% tab title="Command" %}
```text
cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
```
{% endtab %}

{% tab title="Sample output" %}
```
$ cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
```
{% endtab %}
{% endtabs %}

## Have you had a chance to answer the previous question?

Yes, after a few months we finally found the answer. Sadly, Mike is on vacations right now so I'm afraid we are not able to provide the answer at this point.



