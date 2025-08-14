## Check cert-chain in use from Istio logs
```bash
ISTIO_DEPLOYMENT_NAME=istiod-1-16
kubectl -n istio-system logs deploy/$ISTIO_DEPLOYMENT_NAME | grep x509
```
Sample Output:
```bash
2023-04-17T17:33:26.268716Z	info	x509 cert - Issuer: "CN=ext-apps-test-cluster.solo.io", Subject: "", SN: 11d209750e0ecc6bdfdbb95048db54eb, NotBefore: "2023-04-17T17:31:26Z", NotAfter: "2033-04-14T17:33:26Z"
2023-04-17T17:33:26.268758Z	info	x509 cert - Issuer: "CN=Solo.io Istio CA Issuer", Subject: "CN=ext-apps-test-cluster.solo.io", SN: 3dd137af6ca107c78b386ab62629c10bbffc65c9, NotBefore: "2023-04-15T04:30:44Z", NotAfter: "2023-05-15T04:31:14Z"
2023-04-17T17:33:26.268800Z	info	x509 cert - Issuer: "CN=solo.io", Subject: "CN=Solo.io Istio CA Issuer", SN: 3c19afda230a2245afddfffe098e01fd460f2380, NotBefore: "2023-02-16T22:30:08Z", NotAfter: "2028-02-15T22:30:38Z"
2023-04-17T17:33:26.268838Z	info	x509 cert - Issuer: "CN=solo.io", Subject: "CN=solo.io", SN: 2d944288303236ba9f9a6d1c311ab2926cb373b2, NotBefore: "2023-02-16T22:15:44Z", NotAfter: "2033-02-13T22:16:14Z"
```

## Check leaf certs

### Check summary of the leaf cert in use
```bash
NAMESPACE=bookinfo-frontends
DEPLOYMENT_NAME=productpage-v1
istioctl pc secrets -n $NAMESPACE deploy/$DEPLOYMENT_NAME
```

Sample Output:
```bash
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                                        NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           195300121431431074961633844925476808071              2023-04-18T18:11:03Z     2023-04-17T18:09:03Z
ROOTCA            CA             ACTIVE     true           260210890729792376915902803521562131663171056562     2033-02-13T22:16:14Z     2023-02-16T22:15:44Z
```

From the `kubectl -n istio-system logs deploy/$ISTIO_DEPLOYMENT_NAME | grep x509` we could see that the Root CA serial number is `2d944288303236ba9f9a6d1c311ab2926cb373b2`
If we convert this hex (`2d944288303236ba9f9a6d1c311ab2926cb373b2`) to Decimal, it should match with the `SERIAL NUMBER` column value from above for the `ROOTCA` row.
i.e. it should match with `260210890729792376915902803521562131663171056562`

We could use https://www.rapidtables.com/convert/number/hex-to-decimal.html to to the conversion and verify.
![Screenshot 2023-04-17 at 2 36 53 PM](https://user-images.githubusercontent.com/21124287/232580026-429e4460-0633-4af9-ba6e-f858ee238098.png)


### Check details of the leaft cert in use

```bash
NAMESPACE=bookinfo-frontends
DEPLOYMENT_NAME=productpage-v1
istioctl pc secret \
    -n $NAMESPACE deploy/$DEPLOYMENT_NAME -o json | \
    jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | \
    base64 -d | \
    openssl x509 -noout -text
```

Sample Output:
```bash
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            92:ed:6f:69:50:93:d8:3c:f1:4e:29:70:99:5e:a5:87
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = ext-apps-test-cluster.solo.io
        Validity
            Not Before: Apr 17 18:09:03 2023 GMT
            Not After : Apr 18 18:11:03 2023 GMT
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c6:c7:8a:ef:14:14:5e:a2:ed:e1:d6:59:14:62:
                    28:46:9f:a5:f3:db:28:c5:59:05:1b:b3:10:f5:73:
                    87:3c:08:33:60:06:ab:d0:47:52:a3:d9:aa:39:d8:
                    ff:ca:66:a7:aa:ee:f4:22:7e:06:e8:88:6d:23:7b:
                    dc:71:d7:31:4c:c9:06:27:6e:8e:39:15:f5:70:d4:
                    10:48:3f:7b:34:0b:f5:7a:f8:e7:8e:2e:e3:55:da:
                    b9:00:db:7f:12:bb:f8:bd:35:35:53:30:24:f5:ed:
                    b6:b9:c9:bb:e2:09:9a:ee:d9:d5:79:ec:93:ff:49:
                    31:7a:72:47:5d:f9:f9:60:a8:73:18:be:61:56:4b:
                    14:26:85:8b:2f:6b:3b:16:39:9c:7c:74:ab:1a:e2:
                    a4:32:7b:50:2f:97:87:2d:f5:5a:67:c0:10:d7:7b:
                    10:de:3e:90:b0:c7:2c:aa:2f:3b:2c:c9:79:7b:e2:
                    09:4b:c9:c4:cb:73:65:00:15:9d:0c:84:a7:46:f8:
                    ea:f2:f1:86:6a:7f:31:fd:3f:8e:e8:d4:c4:21:e6:
                    4b:05:1b:39:94:53:6f:2b:2e:17:d9:45:68:9f:1c:
                    27:87:eb:ea:bd:d2:bf:bb:c1:d8:c4:c6:d8:36:8d:
                    93:bb:3c:94:3a:ec:cf:7f:3b:5c:b5:a9:2d:5c:fa:
                    16:0d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                C3:99:A9:92:A2:AC:AA:3D:E2:FF:6A:65:B9:A7:1B:2A:AE:D9:3B:16
            X509v3 Subject Alternative Name: critical
                URI:spiffe://ext-apps-test-cluster/ns/bookinfo-frontends/sa/bookinfo-productpage
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        03:e4:c1:38:d4:f5:9d:2f:cd:86:9b:f4:44:8e:87:9e:ab:4c:
        c5:ec:5b:5f:f7:a6:f5:42:7a:bf:75:4c:32:48:4d:0f:e0:b4:
        ae:d2:70:dc:28:cb:12:85:72:b2:12:28:99:96:2c:2c:8a:d6:
        4a:7a:40:42:1a:da:3e:b2:17:a3:0a:f4:30:12:55:f7:d0:c1:
        8d:fb:a6:0a:97:d5:31:d1:29:6b:c5:2d:61:bb:eb:73:d5:e4:
        53:c9:5b:d1:e2:1b:78:5c:59:d0:75:62:d5:77:75:c7:1d:e2:
        99:50:20:c2:0d:cd:13:40:32:53:25:6a:06:30:c1:c0:3d:01:
        50:53:25:ea:a4:ef:28:91:6c:f5:29:25:c6:4a:35:5c:eb:df:
        62:b9:60:83:60:3e:e8:6e:42:61:2e:72:fb:40:6d:e2:1f:6e:
        a0:48:3b:06:f6:4a:55:e6:5e:a9:f7:dd:98:7f:68:80:f6:f6:
        6e:17:10:b3:4d:e3:2f:1f:b8:e8:35:5b:34:41:36:aa:37:60:
        47:89:8a:6f:ac:4c:f3:04:73:b9:a7:0b:56:6d:49:28:5f:c0:
        b9:c4:95:97:6a:08:6d:cd:c8:8d:8b:ab:84:36:4c:14:03:e8:
        8f:40:e5:bd:b7:d7:ee:ca:5f:2f:05:42:61:ac:34:9c:51:50:
        01:67:2b:a0
```

### Check details of the cert chain from istio-proxy container
```bash
kubectl -n $NAMESPACE exec -it deploy/$DEPLOYMENT_NAME -c istio-proxy \
-- openssl s_client -showcerts -connect $ANOTHER_SVC_ON_THE_MESH_NAME.$ANOTHER_SVC_NAMESPACE.svc.cluster.local:$ANOTHER_SVC_PORT
```

Sample variables:
```bash
NAMESPACE=bookinfo-frontends
DEPLOYMENT_NAME=productpage-v1
ANOTHER_SVC_ON_THE_MESH_NAME=details
ANOTHER_SVC_NAMESPACE=bookinfo-backends
ANOTHER_SVC_PORT=9080
```

Sample output:
```bash
CONNECTED(00000003)
depth=3 CN = solo.io
verify error:num=19:self-signed certificate in certificate chain
verify return:1
depth=3 CN = solo.io
verify return:1
depth=2 CN = Solo.io Istio CA Issuer
verify return:1
depth=1 CN = ext-apps-test-cluster.solo.io
verify return:1
depth=0
verify return:1
---
Certificate chain
 0 s:
   i:CN = ext-apps-test-cluster.solo.io
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Apr 17 09:59:19 2023 GMT; NotAfter: Apr 18 10:01:19 2023 GMT
-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIQRuEGLUhHjQIApXLv/d6n3TANBgkqhkiG9w0BAQsFADAo
MSYwJAYDVQQDEx1leHQtYXBwcy10ZXN0LWNsdXN0ZXIuc29sby5pbzAeFw0yMzA0
MTcwOTU5MTlaFw0yMzA0MTgxMDAxMTlaMAAwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQDLasM0sikyVQ4gamOe2SSCLgt2y2PlQSMLEfvgtjA/Bqm2nwKo
hYHSxyps6nhtU1Oizh2dx1jRmc/ohC4C3JcCPgCYfYK4g5zbuI7sFAkwAc/rh+Tg
FuZhkJKwfWQEXeqP0e2IzdcTodeC+lZogHy0fP+l/9YO4888hP7R+IuVwAiQp2nx
ipaJtt6HgPej6bjmjZI9Wiu/RkJoM/Z3xp1W7td512/zUU8w197h3nWcHMZNvWFH
nFvq9fbtJ9/7bR7QgGVj0OFNu6Yc+Q7wH28O6S8aKqvNMC4mOQp+/fmqs9777h9x
wI6gHbX5Ixi//yofN1qagieIa3uuAbuXMsU3AgMBAAGjgbgwgbUwDgYDVR0PAQH/
BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8E
AjAAMB8GA1UdIwQYMBaAFMOZqZKirKo94v9qZbmnGyqu2TsWMFUGA1UdEQEB/wRL
MEmGR3NwaWZmZTovL2V4dC1hcHBzLXRlc3QtY2x1c3Rlci9ucy9ib29raW5mby1i
YWNrZW5kcy9zYS9ib29raW5mby1kZXRhaWxzMA0GCSqGSIb3DQEBCwUAA4IBAQAg
NBd33glzO4wTLsGhB4N73CnLubzqcCzhxG5hGfPqnZzv5PIWepFvm6TJypjHJf72
HrnxKzNcJ1W4EsGdsUI43z4L8uDuIysbjDdHo32vp/IAwWs+4DU+tYd4taqGhqrb
706H680y418ZIVTccDOYRATW7rPcVgYaGFYcXi0z7x00xMtPo6GBfo4/K3WvidDd
y17bLxF/UVMQxDUJBQoTibvohQdz+DjO3Kfw7rSpW+V17aG7E3JPM/sD55tj6R4V
kTj0a9j4eM+Er4uIt4Ss1ngy5EWfMLDW5+lzc5lqnBsUQqOm/3AlpPnoOJAyuOBx
fGvOgngUWrnL89f9lwA7
-----END CERTIFICATE-----
 1 s:CN = ext-apps-test-cluster.solo.io
   i:CN = Solo.io Istio CA Issuer
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Apr 15 04:30:44 2023 GMT; NotAfter: May 15 04:31:14 2023 GMT
-----BEGIN CERTIFICATE-----
MIIDUzCCAjugAwIBAgIUPdE3r2yhB8eLOGq2JinBC7/8ZckwDQYJKoZIhvcNAQEL
BQAwIjEgMB4GA1UEAxMXU29sby5pbyBJc3RpbyBDQSBJc3N1ZXIwHhcNMjMwNDE1
MDQzMDQ0WhcNMjMwNTE1MDQzMTE0WjAoMSYwJAYDVQQDEx1leHQtYXBwcy10ZXN0
LWNsdXN0ZXIuc29sby5pbzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ALMStPpwz9BNjYXIHth4Ua8AffAkn6uF2YxcbRJ2z65J4VqhQPIvQm1qCqDRfCHj
af4GtULfvBGPBohWbRSqH/yftHkGmiVMXPqE9Y1QlwCJt5KOFHQc3b/KeDo+Qno1
m8x+39ZTaqQuiiwyiS25MJ5Lhvc/d2jbizJHoYydVTuls0ZPTzeB0Xxnn6FFG4Fo
oCmZXTXdNDSsZZb7Sds6ZYGC497TjS42zxJ8UVVAIns3UPUfvY2F7TclyPKiXVPq
MRSnP6L4Tp3h0EBr68NeOFQ/f7xHLc43M0IJiRI/go+6YsOlxAtCn5g98VNZ40CL
2sGZxZfQxltZQQgORuwT2e0CAwEAAaN7MHkwDgYDVR0PAQH/BAQDAgEGMA8GA1Ud
EwEB/wQFMAMBAf8wHQYDVR0OBBYEFMOZqZKirKo94v9qZbmnGyqu2TsWMB8GA1Ud
IwQYMBaAFLfExJUOX5+gyideV5I07V/ZbIHmMBYGA1UdEQQPMA2CC2lzdGlvZC0x
LTE2MA0GCSqGSIb3DQEBCwUAA4IBAQCIzAwCWG7vJuTnU7oLBJxfp2QiJTdol1Z1
qxlvBkIt2Q5FEviCTqtstuA17z29rZ4Bpv3Y/GmB2U2ZrDvcXzs/fbS3aVs7yrmf
vIsPPrrLJ+XiTTbtsKrZqEA9zeVq9FyRSdCwkzDQ1p0TXaKePxjT19QFrYZ8dz4R
0dOj1AWgvj4z4cBxQPTw/U//tATtgV0bY19ycxoF7y/7YnwxUz0ylUP4YgzPXdnU
Pa/JGKdHL6rlHQUoqGn1/T8xYNzG3rgnwgoqGxq14YfEMcvYlO6cQ0PDYNik/XrP
zKxM1jmo3Y0BpSE/Acz0JgEsGHIOwSZ1bTf8QF5ahGwx//9cfOdI
-----END CERTIFICATE-----
 2 s:CN = Solo.io Istio CA Issuer
   i:CN = solo.io
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Feb 16 22:30:08 2023 GMT; NotAfter: Feb 15 22:30:38 2028 GMT
-----BEGIN CERTIFICATE-----
MIIEFTCCAv2gAwIBAgIUPBmv2iMKIkWv3f/+CY4B/UYPI4AwDQYJKoZIhvcNAQEL
BQAwEjEQMA4GA1UEAxMHc29sby5pbzAeFw0yMzAyMTYyMjMwMDhaFw0yODAyMTUy
MjMwMzhaMCIxIDAeBgNVBAMTF1NvbG8uaW8gSXN0aW8gQ0EgSXNzdWVyMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuZFeLdUWvLrtuZ93DR4FzX2i0jmD
s5X890kezleElVS2zqKPma9pcwu6VxmuS5dQF65xOoYjLHqq2+AoMgnRVNlI37yq
YICzaH5o5jkM+dHK7b3RCESP7/sBNivuuC8pX254HHJlxX7KzcAvCIe94ielH6//
+q8qGqNCJwNI52rzCsOvuRQy2e5m+QEZkT8DAJY2KDY18yz+0mRxBDWVvRsG7/E7
jdnfzfrK7bjOoRhoxvnux0cUWrR8F0ZXtHAOdvpHXoDeDkmJdg9S5wmRcKDONY94
KIfbqv1WfrKZeeCaTa0YJzctqFs7Ihb0l41fAB3mtqaAFyulfzVl1bmJCwIDAQAB
o4IBUTCCAU0wDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0O
BBYEFLfExJUOX5+gyideV5I07V/ZbIHmMB8GA1UdIwQYMBaAFKvqBAh1nqXF2oMv
fu6eGYvRQNdfMHkGCCsGAQUFBwEBBG0wazBpBggrBgEFBQcwAoZdaHR0cDovL2E5
ZDgxZGMyYzVmZDA0YzRjODQwNTlkNTVkODRmNWU1LTE5NzIyNzEwMTkudXMtd2Vz
dC0yLmVsYi5hbWF6b25hd3MuY29tOjgyMDAvdjEvcGtpL2NhMG8GA1UdHwRoMGYw
ZKBioGCGXmh0dHA6Ly9hOWQ4MWRjMmM1ZmQwNGM0Yzg0MDU5ZDU1ZDg0ZjVlNS0x
OTcyMjcxMDE5LnVzLXdlc3QtMi5lbGIuYW1hem9uYXdzLmNvbTo4MjAwL3YxL3Br
aS9jcmwwDQYJKoZIhvcNAQELBQADggEBAKy2eT7F8jYrUx2dUOpK+LoX4SXlPF2J
Io1N2JbfS5sTnyBLKZoB2UkydO80nPDPH2qGL75rDnxoH3ame1aH/3Fm/Jp3WZxd
hpWf8QnZLkj5kMkkDDPi9pM6ghSkn8PTAlx5wNyIBv5aH1uuMGA1pofThLCUxnCr
6S7wbcH+I0YsbUq+O8uOfU9VyGzMoiLJspVmuHqJjz/A1zRhMd30UWfMqwUzaqYl
f7tVaIGEBs3CEDzcSdd4DuaLZiyUaN3bZhWWgfik0LdLqv7Lfg/UuZvbo8BaOvhY
bhP89vT277BjvENHLQ30S/l5zz6wt8WBKnwMrdz4+FJsMcWxztr9ivQ=
-----END CERTIFICATE-----
 3 s:CN = solo.io
   i:CN = solo.io
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Feb 16 22:15:44 2023 GMT; NotAfter: Feb 13 22:16:14 2033 GMT
-----BEGIN CERTIFICATE-----
MIIDKTCCAhGgAwIBAgIULZRCiDAyNrqfmm0cMRqykmyzc7IwDQYJKoZIhvcNAQEL
BQAwEjEQMA4GA1UEAxMHc29sby5pbzAeFw0yMzAyMTYyMjE1NDRaFw0zMzAyMTMy
MjE2MTRaMBIxEDAOBgNVBAMTB3NvbG8uaW8wggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQDEDrmWZTFpWUMPIXWKXFQV9camFynVJf5oYTaHRiY1X1ojhcF+
y/LaUXyFa2OuNumHKWxyRSMD0xmn6LdcGlngPTSNOGdBE8K3kb2WmEXh2rAH/dKE
H3KbC3r5l/qynPM6BufJt4/5StaKp7BGYgBdAdPrI/h6guqkhzDyD9mqWY+i+t3V
9KrdIUEgZgr/9RXer6Q1RE3XNur+Uh45CDLe0fJAPoys5K8yOWCrebBqZlNDwp6s
ckrnLj8sC8y0zxbl0l8VzWbKvyImsB3w4mNHA93x7KxT15MwQ+2N0/UEfpVe6OJ8
BtRy+Lthst1SpUDg58ecZN/0dlebEi//FPJnAgMBAAGjdzB1MA4GA1UdDwEB/wQE
AwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSr6gQIdZ6lxdqDL37unhmL
0UDXXzAfBgNVHSMEGDAWgBSr6gQIdZ6lxdqDL37unhmL0UDXXzASBgNVHREECzAJ
ggdzb2xvLmlvMA0GCSqGSIb3DQEBCwUAA4IBAQBBJ6Jf+xZeGHgNT4H7WgleRAFG
10oOcvgwW6HIIrehnieTNuRMHIkDenKgEskI0LoZ53I1FvmZ5kYBg2VE6/0FL9F+
Kb5/c3zSSVHAOB6zQRoCJNojeuObhYcJxZzzKdulbHyE0adxLRwZL4KoCqkETTQL
2qSsYUy3mf/s0gnqzcZCOqG6LDh7aB6fR/Mn5n5ymom7baqzH0T172jNwSRIpYbR
H1bSmbR/gmuW7hR/aXQUemoZoASv5uX2kbIXXQuHvArsbEWXIS7FsAIxJ7J9ry2M
ZlOmp638xyb13NR7oejekmXUfY3yZWdAiruHI+8SlYUTd2AjXD8gk3bpC/xc
-----END CERTIFICATE-----
 4 s:CN = solo.io
   i:CN = solo.io
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Feb 16 22:15:44 2023 GMT; NotAfter: Feb 13 22:16:14 2033 GMT
-----BEGIN CERTIFICATE-----
MIIDKTCCAhGgAwIBAgIULZRCiDAyNrqfmm0cMRqykmyzc7IwDQYJKoZIhvcNAQEL
BQAwEjEQMA4GA1UEAxMHc29sby5pbzAeFw0yMzAyMTYyMjE1NDRaFw0zMzAyMTMy
MjE2MTRaMBIxEDAOBgNVBAMTB3NvbG8uaW8wggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQDEDrmWZTFpWUMPIXWKXFQV9camFynVJf5oYTaHRiY1X1ojhcF+
y/LaUXyFa2OuNumHKWxyRSMD0xmn6LdcGlngPTSNOGdBE8K3kb2WmEXh2rAH/dKE
H3KbC3r5l/qynPM6BufJt4/5StaKp7BGYgBdAdPrI/h6guqkhzDyD9mqWY+i+t3V
9KrdIUEgZgr/9RXer6Q1RE3XNur+Uh45CDLe0fJAPoys5K8yOWCrebBqZlNDwp6s
ckrnLj8sC8y0zxbl0l8VzWbKvyImsB3w4mNHA93x7KxT15MwQ+2N0/UEfpVe6OJ8
BtRy+Lthst1SpUDg58ecZN/0dlebEi//FPJnAgMBAAGjdzB1MA4GA1UdDwEB/wQE
AwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSr6gQIdZ6lxdqDL37unhmL
0UDXXzAfBgNVHSMEGDAWgBSr6gQIdZ6lxdqDL37unhmL0UDXXzASBgNVHREECzAJ
ggdzb2xvLmlvMA0GCSqGSIb3DQEBCwUAA4IBAQBBJ6Jf+xZeGHgNT4H7WgleRAFG
10oOcvgwW6HIIrehnieTNuRMHIkDenKgEskI0LoZ53I1FvmZ5kYBg2VE6/0FL9F+
Kb5/c3zSSVHAOB6zQRoCJNojeuObhYcJxZzzKdulbHyE0adxLRwZL4KoCqkETTQL
2qSsYUy3mf/s0gnqzcZCOqG6LDh7aB6fR/Mn5n5ymom7baqzH0T172jNwSRIpYbR
H1bSmbR/gmuW7hR/aXQUemoZoASv5uX2kbIXXQuHvArsbEWXIS7FsAIxJ7J9ry2M
ZlOmp638xyb13NR7oejekmXUfY3yZWdAiruHI+8SlYUTd2AjXD8gk3bpC/xc
-----END CERTIFICATE-----
---
Server certificate
subject=
issuer=CN = ext-apps-test-cluster.solo.io
---
Acceptable client certificate CA names
CN = solo.io
Requested Signature Algorithms: ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:RSA-PSS+SHA512:RSA+SHA512:RSA+SHA1
Shared Requested Signature Algorithms: ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:RSA-PSS+SHA512:RSA+SHA512
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 4978 bytes and written 455 bytes
Verification error: self-signed certificate in certificate chain
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 19 (self-signed certificate in certificate chain)
---
80BB561AED7F0000:error:0A00045C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required:../ssl/record/rec_layer_s3.c:1584:SSL alert number 116
command terminated with exit code 1
```

### Converting the encoded certificates to readable text

From Mac:
- Copy the certificate in the clipboard
- Run the following
```bash
pbpaste | openssl x509 -noout -text
```
