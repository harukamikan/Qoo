git checkout main const _BubbleContent({
    required this.text,
    this.title,
    this.icon,
    required this.textColor,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        if (icon != null) Icon(icon, color: textColor, size: 20),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: big ? 22 : 14,
          ),
        ),
      ],
    );
  }
}