import argparse
import os.path
import yaml


def write_to_file(custom_resource):
    if not os.path.exists('./crs'):
        os.mkdir('./crs')
    kind = custom_resource.get('kind')
    kind_dir = './crs/' + kind
    if not os.path.exists(kind_dir):
        os.mkdir(kind_dir)
    metadata = custom_resource.get('metadata')
    name = metadata.get('name')
    output_filename = kind_dir + '/' + name + '.yaml'
    with open(output_filename, 'w') as yaml_file:
        print('Creating ' + output_filename)
        yaml.dump(custom_resource, yaml_file)


def parse_crs(yaml_input):
    print('Parsing ' + yaml_input)
    print('WARNING: If your file is really big, this may take a minute!')
    with open(yaml_input, 'r') as file:
        crs = yaml.safe_load(file)
        items = crs.get('items')
        for cr in items:
            write_to_file(cr)


def parse_nodes(node_input):
    print('Parsing ' + node_input)
    file = open(node_input, 'r')
    lines = file.readlines()
    capacity = False

    for line in lines:
        if line.startswith("Name: "):
            name = line.split(' ', 1)[1].strip()
        if line.startswith("Roles: "):
            roles = line.split(' ', 1)[1].strip()
        if line.startswith("Capacity"):
            capacity = True
        if capacity and line.startswith('  cpu:'):
            cpu = line.split('  cpu:', 1)[1].strip()
            print(name + ' ' + roles + ' ' + cpu)
            capacity = False


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("op", help="Operation you want.  One of crparse or nodeparse")
    parser.add_argument("file", help="File containing information that you want to parse")
    args = parser.parse_args()
    if args.op == 'crparse':
        parse_crs(args.file)
    elif args.op == 'nodeparse':
        parse_nodes(args.file)
    else:
        print('Sorry, you need to ask for either crparse or nodeparse.')

