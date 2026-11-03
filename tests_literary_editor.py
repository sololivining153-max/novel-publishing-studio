from app.literary_editor import local_checks,build_prompt,validate_report,compare_versions

def test_checks():
    assert local_checks("One sentence. Another sentence.")["sentence_count"]==2

def test_prompt():
    assert "Line" in build_prompt("A long enough sample passage.","line")

def test_validation():
    r=validate_report({"findings":[{"severity":"bad","confidence":3}]})
    assert r["findings"][0]["severity"]=="note" and r["findings"][0]["confidence"]==1

def test_compare():
    assert compare_versions("old","new")["changes"]
