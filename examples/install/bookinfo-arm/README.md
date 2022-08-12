# Book info for arm (MAC M1)

run: 

```bash
./build.sh <version> <repo>
```

This is generate the following images, example: 

```text
asayah/examples-bookinfo-reviews-v2                               1.0                                c7912ebb17e3   8 minutes ago    149MB
asayah/examples-bookinfo-reviews-v2                               latest                             c7912ebb17e3   8 minutes ago    149MB
asayah/examples-bookinfo-reviews-v3                               1.0                                5b9208639970   8 minutes ago    149MB
asayah/examples-bookinfo-reviews-v3                               latest                             5b9208639970   8 minutes ago    149MB
asayah/examples-bookinfo-reviews-v1                               1.0                                fcd51f33d306   8 minutes ago    149MB
asayah/examples-bookinfo-reviews-v1                               latest                             fcd51f33d306   8 minutes ago    149MB
```

# Run Bookinfo demo on arm: 

```bash 
kubectl apply -f bookinfo.yaml
```