import os
import re

REPO_URL = "https://github.com/PRappalini/OBSERVABILITY-IAC-GRAFANA_STACK-AWS/blob/master"


def on_pre_build(config):
    """
    Sync root-level Internal-Documentation.md into docs/ directory,
    adjusting relative root links for MkDocs compilation.
    """
    base_dir = os.path.dirname(config["config_file_path"])
    docs_dir = config["docs_dir"]

    src = os.path.join(base_dir, "Internal-Documentation.md")
    dst = os.path.join(docs_dir, "Internal-Documentation.md")

    if not os.path.exists(src):
        return

    with open(src, "r", encoding="utf-8") as f:
        content = f.read()

    # Adjust diagram links from docs/architecture.* to architecture.* for MkDocs
    content = content.replace("docs/architecture.png", "architecture.png")
    content = content.replace("docs/architecture.html", "architecture.html")
    content = content.replace("docs/architecture.drawio", "architecture.drawio")

    # Replace relative repository links (terraform/, docker/, .github/) with GitHub repository URLs
    # Example: (terraform/ec2.tf) -> (https://github.com/.../blob/master/terraform/ec2.tf)
    content = re.sub(
        r"\(((?:terraform|docker|\.github)[^)\s]+)\)",
        rf"({REPO_URL}/\1)",
        content,
    )

    with open(dst, "w", encoding="utf-8") as f:
        f.write(content)
