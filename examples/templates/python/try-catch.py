try:
    {{__selection__}}
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
