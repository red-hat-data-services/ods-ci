import glob


class ReadPR:
    """
    Recursive find '*** Keywords ***' text relationship for the files that were changed.
    For each match retrieve and report what are the tags that we should run the test suite.
    """

    def __init__(self):
        self.keyword_key = "*** Keywords ***"
        self.magic_tag_separator = "_______"
        self.magic_tag = "[Tags]"

    def run(self):
        data = self.get_diff()
        files_changed = [line for line in data if line.startswith("diff --git ")]
        infos = []
        for f in files_changed:
            if f.endswith((".robot", ".resource")):
                infos.append(self.get_sections_info(f))

        all_tags = set()
        for info in infos:
            tags = self.search_content_tag(info)
            all_tags = all_tags.union(tags)
        self.generate_arg_commands(all_tags)

    def generate_arg_commands(self, all_tags):
        destructive_tests = []
        slow_tests = []
        fast_tests = []
        ods_tests = []
        for ft in all_tags:
            if ft == "DestructiveTest":
                destructive_tests.append(self.parse_tag(ft))
            elif ft.startswith("Execution-Time-Over") or ft == "Tier3" or ft == "Tier1" or ft == "Sanity":
                slow_tests.append(self.parse_tag(ft))
            elif ft.startswith("ODS-"):
                ods_tests.append(self.parse_tag(ft))
            else:
                fast_tests.append(self.parse_tag(ft))

        print(f"destructive_tests: {' '.join(destructive_tests)}")
        print(f"slow_tests: {' '.join(slow_tests)}")
        print(f"fast_tests: {' '.join(fast_tests)}")
        print(f"ods_tests: {' '.join(ods_tests)}")

    def parse_tag(self, t):
        return f"--include {t}"

    def search_content_tag(self, info):
        all_tags_file = set()
        my_path = "../../tests/Tests"
        files = sorted(glob.glob(my_path + "/**/*.robot", recursive=True))
        for filename in info:
            for section_name in info[filename]:
                section_data = info[filename][section_name]
                for sd in section_data:
                    for file in files:
                        tags = self.search_content(file, sd)
                        all_tags_file = all_tags_file.union(tags)
        return all_tags_file

    def search_content(self, filename, content):
        with open(filename, "r") as fp:
            # read all lines in a list
            lines = fp.readlines()
            found_content = False
            for line in lines:
                # easy to debug -> if content in line
                if line.strip().startswith(content):
                    found_content = True
                    break
            if found_content:
                return self.find_tags(lines)
            else:
                return []

    def find_tags(self, lines):
        started = False
        tags = []
        for line in lines:
            if self.magic_tag in line:
                started = True
            if started:
                if self.magic_tag in line:
                    # first line
                    index_tag = line.index(self.magic_tag) + len(self.magic_tag)
                    tag = line[index_tag:]
                elif "..." in line:
                    # >= second line
                    tag = line.replace("...", " ").strip().replace("\n", "")
                else:
                    started = False
                    continue
                if started:
                    tag = tag.strip().replace("\n", "")
                    # multiple tag in one line or a tag with comments
                    if "#" in tag:
                        # remove comment
                        tag = tag[: tag.index("#")]
                    tag_data = tag.replace(" ", self.magic_tag_separator).split(self.magic_tag_separator)
                    for tag_it in tag_data:
                        tag_it = tag_it.strip()
                        if len(tag_it) > 0:
                            tags.append(tag_it)
        return tags

    def get_sections_info(self, robot_file):
        file_name, lines = self.get_file_lines(robot_file)
        section_name = None
        section_data = []
        sections_info = {}

        for line in lines:
            if line.startswith("***"):
                # after each ***
                self.apply_section_rule(section_name, section_data, sections_info, file_name)

                if self.keyword_key in line:
                    section_name = self.keyword_key
                    section_data = []
                else:
                    section_name = None
                    section_data = []

                continue
            if section_name is not None and len(line.strip()) > 0:
                section_data.append(line)

        # last ***
        self.apply_section_rule(section_name, section_data, sections_info, file_name)

        return sections_info

    def apply_section_rule(self, section_name, section_data, sections_info, file_name):
        if section_name is not None:
            if file_name not in sections_info:
                sections_info[file_name] = {}
            if section_name == self.keyword_key:
                r = self.get_keywords(section_data)
                sections_info[file_name][section_name] = r

    def get_keywords(self, section_data):
        keywords = []
        for sd in section_data:
            if not sd.startswith(" "):
                keywords.append(sd.replace("\n", ""))
        return keywords

    def get_file_lines(self, file_path):
        file_path = file_path.split(" ")[-1]
        file_name = f"../../../{file_path[2:]}"
        if file_path.startswith("b/"):
            with open(file_name) as f:
                lines = f.readlines()
            return file_name, lines
        else:
            raise ValueError(f"cannot find the path starting with b/ -> {file_path}")

    def get_diff(self, target="git diff upstream/main"):
        import subprocess

        output = subprocess.getoutput(target)
        return output.split("\n")


if __name__ == "__main__":
    ReadPR().run()
