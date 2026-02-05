import 'theme_colors_data.dart';

/// 24节气传统色彩数据库
/// 参考：郭浩《中国传统色：故宫里的色彩美学》
final List<SeasonData> allSeasons = [
  // --- 春生 (Spring) ---
  SeasonData(AppSeason.spring, "春生", [
    SolarTerm(
      name: "立春",
      pinyin: "Lì Chūn",
      colors: [
        TraditionalColor("黄白游", "#FFF799"),
        TraditionalColor("松花", "#FFEE6F"),
        TraditionalColor("缃叶", "#ECD452"),
        TraditionalColor("苍黄", "#B6A014"),
      ],
    ),
    SolarTerm(
      name: "雨水",
      pinyin: "Yǔ Shuǐ",
      colors: [
        TraditionalColor("盈盈", "#F9D3E3"),
        TraditionalColor("水红", "#ECB0C1"),
        TraditionalColor("苏梅", "#DD7694"),
        TraditionalColor("紫茎屏风", "#A76283"),
      ],
    ),
    SolarTerm(
      name: "惊蛰",
      pinyin: "Jīng Zhé",
      colors: [
        TraditionalColor("赤缇", "#BA5B49"),
        TraditionalColor("朱草", "#A64036"),
        TraditionalColor("绮钱", "#9E2A22"),
        TraditionalColor("顺圣", "#7C191E"),
      ],
    ),
    SolarTerm(
      name: "春分",
      pinyin: "Chūn Fēn",
      colors: [
        TraditionalColor("皦玉", "#EBEEE8"),
        TraditionalColor("吉量", "#EBEDDF"),
        TraditionalColor("韶粉", "#E0E0D0"),
        TraditionalColor("霜地", "#C7C6B6"),
      ],
    ),
    SolarTerm(
      name: "清明",
      pinyin: "Qīng Míng",
      colors: [
        TraditionalColor("紫蒲", "#A6559D"),
        TraditionalColor("赪紫", "#8A1874"),
        TraditionalColor("齐紫", "#6C216D"),
        TraditionalColor("凝夜紫", "#422256"),
      ],
    ),
    SolarTerm(
      name: "谷雨",
      pinyin: "Gǔ Yǔ",
      colors: [
        TraditionalColor("昌荣", "#DCC7E1"),
        TraditionalColor("紫薄汗", "#BBA1CB"),
        TraditionalColor("茈藐", "#A67EB7"),
        TraditionalColor("紫结", "#7D5284"),
      ],
    ),
  ]),

  // --- 夏长 (Summer) ---
  SeasonData(AppSeason.summer, "夏长", [
    SolarTerm(
      name: "立夏",
      pinyin: "Lì Xià",
      colors: [
        TraditionalColor("青桑", "#C3D94E"),
        TraditionalColor("翠缥", "#B7D332"),
        TraditionalColor("人籁", "#9EBC19"),
        TraditionalColor("水龙吟", "#84A729"),
      ],
    ),
    SolarTerm(
      name: "小满",
      pinyin: "Xiǎo Mǎn",
      colors: [
        TraditionalColor("彤管", "#E2A2AC"),
        TraditionalColor("渥赭", "#DD6B7B"),
        TraditionalColor("唇脂", "#C25160"),
        TraditionalColor("朱孔阳", "#B81A35"),
      ],
    ),
    SolarTerm(
      name: "芒种",
      pinyin: "Máng Zhòng",
      colors: [
        TraditionalColor("鶸雾", "#D5D1AE"),
        TraditionalColor("瓷秘", "#BFC096"),
        TraditionalColor("琬琰", "#A9A886"),
        TraditionalColor("青圭", "#92905D"),
      ],
    ),
    SolarTerm(
      name: "夏至",
      pinyin: "Xià Zhì",
      colors: [
        TraditionalColor("赩炽", "#CB523E"),
        TraditionalColor("石榴裙", "#B13B2E"),
        TraditionalColor("朱湛", "#95302E"),
        TraditionalColor("大繎", "#822327"),
      ],
    ),
    SolarTerm(
      name: "小暑",
      pinyin: "Xiǎo Shǔ",
      colors: [
        TraditionalColor("骍刚", "#F5B087"),
        TraditionalColor("赪霞", "#F18F60"),
        TraditionalColor("赪尾", "#EF845D"),
        TraditionalColor("朱柿", "#ED6D46"),
      ],
    ),
    SolarTerm(
      name: "大暑",
      pinyin: "Dà Shǔ",
      colors: [
        TraditionalColor("夕岚", "#E3ADB9"),
        TraditionalColor("雌霓", "#CF929E"),
        TraditionalColor("绛纱", "#B27777"),
        TraditionalColor("茹藘", "#A35F65"),
      ],
    ),
  ]),

  // --- 秋收 (Autumn) ---
  SeasonData(AppSeason.autumn, "秋收", [
    SolarTerm(
      name: "立秋",
      pinyin: "Lì Qiū",
      colors: [
        TraditionalColor("窃蓝", "#88ABDA"),
        TraditionalColor("监德", "#6F94CD"),
        TraditionalColor("苍苍", "#5976BA"),
        TraditionalColor("群青", "#2E59A7"),
      ],
    ),
    SolarTerm(
      name: "处暑",
      pinyin: "Chǔ Shǔ",
      colors: [
        TraditionalColor("退红", "#F0CFE3"),
        TraditionalColor("樱花", "#E4B8D5"),
        TraditionalColor("丁香", "#CE93BF"),
        TraditionalColor("木槿", "#BA79B1"),
      ],
    ),
    SolarTerm(
      name: "白露",
      pinyin: "Bái Lù",
      colors: [
        TraditionalColor("凝脂", "#F5F2E9"),
        TraditionalColor("玉色", "#EAE4D1"),
        TraditionalColor("黄润", "#DFD6B8"),
        TraditionalColor("缣缃", "#D5C8A0"),
      ],
    ),
    SolarTerm(
      name: "秋分",
      pinyin: "Qiū Fēn",
      colors: [
        TraditionalColor("卵色", "#D5E3D4"),
        TraditionalColor("葭灰", "#CAD7C5"),
        TraditionalColor("冰台", "#BECAB7"),
        TraditionalColor("青古", "#B3BDA9"),
      ],
    ),
    SolarTerm(
      name: "寒露",
      pinyin: "Hán Lù",
      colors: [
        TraditionalColor("酡颜", "#D9B8BC"),
        TraditionalColor("翠涛", "#9EBC9A"),
        TraditionalColor("青梅", "#778A77"),
        TraditionalColor("翕赩", "#5F766A"),
      ],
    ),
    SolarTerm(
      name: "霜降",
      pinyin: "Shuāng Jiàng",
      colors: [
        TraditionalColor("银朱", "#D12920"),
        TraditionalColor("胭脂虫", "#AB1D22"),
        TraditionalColor("朱樱", "#8F1D22"),
        TraditionalColor("爵头", "#631216"),
      ],
    ),
  ]),

  // --- 冬藏 (Winter) ---
  SeasonData(AppSeason.winter, "冬藏", [
    SolarTerm(
      name: "立冬",
      pinyin: "Lì Dōng",
      colors: [
        TraditionalColor("半见", "#FFFBC7"),
        TraditionalColor("女贞黄", "#F7EEAD"),
        TraditionalColor("绢纨", "#ECE093"),
        TraditionalColor("姜黄", "#D6C560"),
      ],
    ),
    SolarTerm(
      name: "小雪",
      pinyin: "Xiǎo Xuě",
      colors: [
        TraditionalColor("龙膏烛", "#DE82A7"),
        TraditionalColor("黡紫", "#CC73A0"),
        TraditionalColor("胭脂水", "#B95A89"),
        TraditionalColor("胭脂紫", "#B0436F"),
      ],
    ),
    SolarTerm(
      name: "大雪",
      pinyin: "Dà Xuě",
      colors: [
        TraditionalColor("粉米", "#EFC4CE"),
        TraditionalColor("缥缘", "#CE8892"),
        TraditionalColor("美人祭", "#C35C6A"),
        TraditionalColor("鞓红", "#B04552"),
      ],
    ),
    SolarTerm(
      name: "冬至",
      pinyin: "Dōng Zhì",
      colors: [
        TraditionalColor("银红", "#E7CAD3"),
        TraditionalColor("莲红", "#D9A0B3"),
        TraditionalColor("紫梅", "#BB7A8C"),
        TraditionalColor("紫矿", "#9E4E56"),
      ],
    ),
    SolarTerm(
      name: "小寒",
      pinyin: "Xiǎo Hán",
      colors: [
        TraditionalColor("郎白", "#F6F9E4"),
        TraditionalColor("断肠", "#ECEBC2"),
        TraditionalColor("田赤", "#E1D384"),
        TraditionalColor("黄封", "#CAB272"),
      ],
    ),
    SolarTerm(
      name: "大寒",
      pinyin: "Dà Hán",
      colors: [
        TraditionalColor("紫府", "#995D7F"),
        TraditionalColor("地血", "#814662"),
        TraditionalColor("芥拾紫", "#602641"),
        TraditionalColor("油紫", "#420B2F"),
      ],
    ),
  ]),
];
